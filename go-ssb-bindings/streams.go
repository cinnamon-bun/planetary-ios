package main

import (
	"bytes"
	"context"
	"encoding/json"
	"time"

	"github.com/go-kit/kit/log/level"

	"github.com/cryptix/go/encodedTime"
	"github.com/pkg/errors"
	"go.cryptoscope.co/luigi"
	"go.cryptoscope.co/margaret"
	"go.cryptoscope.co/ssb"
	"go.cryptoscope.co/ssb/private"
)

import "C"

//export ssbStreamRootLog
func ssbStreamRootLog(seq uint64, limit int) *C.char {
	var err error
	defer func() {
		if err != nil {
			level.Error(log).Log("ssbStreamRootLog", err)
		}
	}()

	lock.Lock()
	if sbot == nil {
		err = ErrNotInitialized
		lock.Unlock()
		return nil
	}
	lock.Unlock()

	buf, err := newLogDrain(sbot.RootLog, seq, limit)
	if err != nil {
		err = errors.Wrap(err, "rootLog: draining failed")
		return nil
	}

	return C.CString(buf.String())
}

//export ssbStreamPrivateLog
func ssbStreamPrivateLog(seq uint64, limit int) *C.char {
	var err error
	defer func() {
		if err != nil {
			level.Error(log).Log("ssbStreamPrivateLog", err)
		}
	}()

	lock.Lock()
	if sbot == nil {
		err = ErrNotInitialized
		return nil
	}
	lock.Unlock()

	pl, ok := sbot.GetMultiLog("privLogs")
	if !ok {
		err = errors.Errorf("sbot: missing privLogs index")
		return nil
	}

	userPrivs, err := pl.Get(sbot.KeyPair.Id.StoredAddr())
	if err != nil {
		err = errors.Wrap(err, "failed to open user private index")
		return nil
	}

	unboxlog := private.NewUnboxerLog(sbot.RootLog, userPrivs, sbot.KeyPair)
	buf, err := newLogDrain(unboxlog, seq, limit)
	if err != nil {
		err = errors.Wrap(err, "PrivateLog: pipe draining failed")
		return nil
	}

	return C.CString(buf.String())
}

func newLogDrain(sourceLog margaret.Log, seq uint64, limit int) (*bytes.Buffer, error) {
	start := time.Now()

	w := &bytes.Buffer{}

	src, err := sourceLog.Query(
		margaret.SeqWrap(true),
		margaret.Gte(margaret.BaseSeq(seq)),
		margaret.Limit(limit))
	if err != nil {
		return nil, errors.Wrapf(err, "drainLog: failed to open query")
	}

	i := 0
	w.WriteString("[")
	for {
		v, err := src.Next(context.Background())
		if err != nil {
			if luigi.IsEOS(err) {
				w.WriteString("]")
				break
			}
			return nil, errors.Wrapf(err, "drainLog: failed to drain log msg:%d", i)
		}

		sw, ok := v.(margaret.SeqWrapper)
		if !ok {
			if errv, ok := v.(error); ok && margaret.IsErrNulled(errv) {
				continue
			}
			return nil, errors.Errorf("drainLog: want wrapper type got: %T", v)
		}

		rxLogSeq := sw.Seq().Seq()
		wrappedVal := sw.Value()
		msg, ok := wrappedVal.(ssb.Message)
		if !ok {
			return nil, errors.Errorf("drainLog: want msg type got: %T", wrappedVal)
		}

		if i > 0 {
			w.WriteString(",")
		}

		var kv struct {
			ssb.KeyValueRaw
			ReceiveLogSeq int64 // the sequence no of the log its stored in
		}
		kv.ReceiveLogSeq = rxLogSeq
		kv.Key_ = msg.Key()
		kv.Value = *msg.ValueContent()
		kv.Timestamp = encodedTime.Millisecs(msg.Received())
		if err := json.NewEncoder(w).Encode(kv); err != nil {
			return nil, errors.Wrapf(err, "drainLog: failed to k:v map message %d", i)
		}

		i++
	}

	if i > 0 {
		durr := time.Since(start)
		level.Info(log).Log("event", "fresh viewdb chunk", "msgs", i, "took", durr)
	}
	return w, nil

}
