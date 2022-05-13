// Copyright 2015 The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//go:build !nomeminfo
// +build !nomeminfo

package collector

// #include <mach/mach_host.h>
// #include <sys/sysctl.h>
// #include <libproc.h>
// #include <sys/proc_info.h>
// typedef struct xsw_usage xsw_usage_t;
import "C"

import (
	"encoding/binary"
	"fmt"
	"unsafe"

	"golang.org/x/sys/unix"
)

func (c *meminfoCollector) getMemInfo() (map[string]float64, error) {
	host := C.mach_host_self()
	infoCount := C.mach_msg_type_number_t(C.HOST_VM_INFO64_COUNT)
	vmstat := C.vm_statistics64_data_t{}
	procInfo := C.proc_taskinfo
	C.proc_pidinfo(20080, C.PROC_PIDTASKINFO, 0, unsafe.Pointer(&procInfo), C.PROC_PIDTASKINFO_SIZE)
	ret := C.host_statistics64(
		C.host_t(host),
		C.HOST_VM_INFO64,
		C.host_info_t(unsafe.Pointer(&vmstat)),
		&infoCount,
	)
	if ret != C.KERN_SUCCESS {
		return nil, fmt.Errorf("Couldn't get memory statistics, host_statistics returned %d", ret)
	}
	totalb, err := unix.Sysctl("hw.memsize")
	if err != nil {
		return nil, err
	}

	swapraw, err := unix.SysctlRaw("vm.swapusage")
	if err != nil {
		return nil, err
	}
	swap := (*C.xsw_usage_t)(unsafe.Pointer(&swapraw[0]))

	// Syscall removes terminating NUL which we need to cast to uint64
	total := binary.LittleEndian.Uint64([]byte(totalb + "\x00"))

	var pageSize C.vm_size_t
	C.host_page_size(C.host_t(host), &pageSize)

	ps := float64(pageSize)
	return map[string]float64{
		"active_pages":     float64(vmstat.active_count),
		"inactive_pages":   float64(vmstat.inactive_count),
		"wired_pages":      float64(vmstat.wire_count),
		"anonymous_pages":  float64(vmstat.internal_page_count),
		"filesystem_pages": float64(vmstat.external_page_count),
		"free_pages":       float64(vmstat.free_count),
		// https://apple.stackexchange.com/a/347056
		"speculative_pages": float64(vmstat.speculative_count),
		// # of pages used by the compressed pager to hold all the compressed data
		"compressed_pages":        float64(vmstat.compressor_page_count),
		"swapped_in_pages_total":  float64(vmstat.swapins),
		"swapped_out_pages_total": float64(vmstat.swapouts),
		"cow_faults":              float64(vmstat.cow_faults),
		"zero_filled_pages":       float64(vmstat.zero_fill_count),
		"total_faults":            float64(vmstat.faults),
		"total_bytes":             ps * float64(total),
		"swap_used_bytes":         float64(swap.xsu_used),
		"swap_total_bytes":        float64(swap.xsu_total),
	}, nil
}
