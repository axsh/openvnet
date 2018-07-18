package utils

import (
	"errors"
	"log"
	"strings"
)

var (
	// TODO: decide on a max for this based on hardware limits
	// if linux only, memQuicklyAvailableForProcesses = (roughly)
	//   /proc/meminfo/MemFree
	//   + /proc/meminfo/ActiveFile
	//   + /proc/meminfo/InactiveFile
	//   - $(cat /proc/sys/vm/min_free_kbytes)

	// goroutineStackMem = int32(4096) // changes with go version -- so far has varied from 2 to 8 kB
	// if snapshotlen > 4096{goroutineStackMem = snapshotLen}
	// golimit = memQuicklyAvailableForProcesses/int(goroutineStackMem)
	// this gives roughly 250,000 per GB of RAM for packet sizes up to 4kB
	// superJumboPackets could take up to 16 times more memory, giving roughly
	// 15,000 per GB of RAM as a slightly conservative value.

	// TODO: This is more likely to be cpu bound, so something like the above
	// should be computed for the cpu usage...
	// goCpuLimit = ...
	// if goCpuLimit > golimit { golimit=goCpuLimit }
	golimit = 10000
	limiter = make(chan struct{}, golimit)
)

// LimitedGo is a wrapper to launch goroutines with a limit of golimit. This
// could be done with waitgroups, but not without either introducing race
// conditions or using substantially more resources and dangerous recursive
// calls. It could also be done with semaphores, but at the time of writing this
// (2018.07.12) the golang.org/x/sync/semaphore package is designed to use
// context.Context objects. LimitedGo acts very similarly to semaphores.
// LimitedGo is synchronous and concurrency safe with minimal resource usage.
func LimitedGo(f func()) {
	limiter <- struct{}{}
	go func() {
		defer func() { <-limiter }()
		f()
	}()
}

// Join joins arbitrary strings
func Join(args ...string) string {
	return strings.Join(args, "")
}

// Join joins arbitrary strings separated by any arbitrary string
func JoinWithSep(separator string, args ...string) string {
	return strings.Join(args, separator)
}

func CatchErr(err error, msg ...string) {
	if err != nil {
		log.Println(msg, err)
	}
}

func ReturnErr(err error, msg ...string) error {
	if err != nil {
		return errors.New(Join(Join(msg...), err.Error()))
	}
	return nil
}
