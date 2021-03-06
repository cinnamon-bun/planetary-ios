// SPDX-License-Identifier: MIT

package roaringfiles

import (
	"context"
	"strings"

	"github.com/pkg/errors"
	"go.cryptoscope.co/luigi"
	"go.cryptoscope.co/margaret"
)

type query struct {
	log *sublog

	nextSeq, lt margaret.BaseSeq

	limit   int
	live    bool
	seqWrap bool
}

func (qry *query) Gt(s margaret.Seq) error {
	if qry.nextSeq > margaret.SeqEmpty {
		return errors.Errorf("lower bound already set")
	}

	qry.nextSeq = margaret.BaseSeq(s.Seq() + 1)
	return nil
}

func (qry *query) Gte(s margaret.Seq) error {
	if qry.nextSeq > margaret.SeqEmpty {
		return errors.Errorf("lower bound already set")
	}

	qry.nextSeq = margaret.BaseSeq(s.Seq())
	return nil
}

func (qry *query) Lt(s margaret.Seq) error {
	if qry.lt != margaret.SeqEmpty {
		return errors.Errorf("upper bound already set")
	}

	qry.lt = margaret.BaseSeq(s.Seq())
	return nil
}

func (qry *query) Lte(s margaret.Seq) error {
	if qry.lt != margaret.SeqEmpty {
		return errors.Errorf("upper bound already set")
	}

	qry.lt = margaret.BaseSeq(s.Seq() + 1)
	return nil
}

func (qry *query) Limit(n int) error {
	qry.limit = n
	return nil
}

func (qry *query) Live(live bool) error {
	qry.live = live
	return nil
}

func (qry *query) SeqWrap(wrap bool) error {
	qry.seqWrap = wrap
	return nil
}

func (qry *query) Reverse(rev bool) error {
	if rev == false {
		return nil
	}
	return errors.Errorf("TODO:reverse")
}

func (qry *query) Next(ctx context.Context) (interface{}, error) {
	qry.log.Lock()

	if qry.limit == 0 {
		qry.log.Unlock()
		return nil, luigi.EOS{}
	}
	qry.limit--

	if qry.nextSeq == margaret.SeqEmpty {
		qry.nextSeq = 0
	}

	if qry.lt != margaret.SeqEmpty {
		if qry.nextSeq >= qry.lt {
			qry.log.Unlock()
			return nil, luigi.EOS{}
		}
	}

	var v interface{}
	seqVal, err := qry.log.bmap.Select(uint32(qry.nextSeq.Seq()))
	v = margaret.BaseSeq(seqVal)
	if err != nil {
		if !strings.Contains(err.Error(), "th integer in a bitmap with only ") {
			qry.log.Unlock()
			return nil, errors.Wrapf(err, "roaringfiles/qry: error in read transaction (%T)", err)
		}

		// key not found, so we reached the end
		// abort if not a live query, else wait until it's written
		if !qry.live {
			qry.log.Unlock()
			return nil, luigi.EOS{}
		}

		return qry.livequery(ctx)
	}

	if qry.seqWrap {
		v = margaret.WrapWithSeq(v, qry.nextSeq)
		qry.nextSeq++
		qry.log.Unlock()
		return v, nil
	}

	qry.nextSeq++
	qry.log.Unlock()
	return v, nil
}

func (qry *query) livequery(ctx context.Context) (interface{}, error) {
	thisNextSeq := qry.nextSeq
	qry.log.Unlock()

	var (
		v   interface{}
		err error
	)

	select {
	case <-qry.log.seq.WaitFor(uint64(thisNextSeq)):
		v, err = qry.log.get(thisNextSeq)
		if !qry.seqWrap { // simpler to have two +1's here then a defer
			qry.nextSeq++
		}
	case <-ctx.Done():
		err = errors.Wrap(ctx.Err(), "cancelled while waiting for value to be written")
	}

	if err != nil {
		return nil, errors.Wrap(err, "livequery failed to retreive value")
	}

	if qry.seqWrap {
		v = margaret.WrapWithSeq(v, qry.nextSeq)
		qry.nextSeq++
		return v, nil
	}

	return v, err
}
