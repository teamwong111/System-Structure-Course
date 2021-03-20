# System-Structure-Course
[中文文档](https://github.com/teamwong111/System-Structure-Course/blob/main/README-cn.md)

It is my term project repo of System Structure Course(2020) in Tongji University

---

## Contents
- Introduction
- Project Directory Structure
- Defenders
- License

---

## Introduction
This repo contain the three term project of Tongji University's System Structure Course in 2020.
1. static-pipeline-cpu
2. dynamic-pipeline-cpu
3. tertiary-storage-cpu

---

## Project Directory Structure
```bash
.
├─dynamic-pipeline
│  ├─report
│  │  └─report.pdf
│  └─code
│     ├─alu.v
│     ├─branchpredict.v
│     ├─clk_wiz.v
│     ├─controlunit.v
│     ├─cp0.v
│     ├─dmem.v
│     ├─Execute.v
│     ├─hi_lo.v
│     ├─imem.v
│     ├─Instdecode.v
│     ├─Instfetch.v
│     ├─Memory.v
│     ├─regfile.v
│     ├─sccomp_dataflow.v
│     ├─seg7x16.v
│     └─Writeback.v     
├─static-pipeline
│  ├─report
│  │  └─report.pdf
│  └─code
│     ├─alu.v
│     ├─branchpredict.v
│     ├─controlunit.v
│     ├─cp0.v
│     ├─Datamemory.v
│     ├─dmem.v
│     ├─Execute.v
│     ├─hi_lo.v
│     ├─imem.v
│     ├─InstDecode.v
│     ├─InstFetch.v
│     ├─Memory.v
│     ├─regfile.v
│     ├─sccomp_dataflow.v
│     ├─seg7x16.v
│     └─Writeback.v
│─tertiary-storage
│  ├─report
│  │  └─report.pdf
│  └─code
│      ├─alu.v
│      ├─branchpredict.v
│      ├─cache.v
│      ├─controlunit.v
│      ├─cp0.v
│      ├─ddr_read_control.v
│      ├─ddr_write_control.v
│      ├─ddr_write_read.v
│      ├─dmem.v
│      ├─Execute.v
│      ├─hi_lo.v
│      ├─Instdecode.v
│      ├─Instfetch.v
│      ├─Memory.v
│      ├─regfile.v
│      ├─sccomp_dataflow.v
│      ├─sd_ctrl.v
│      ├─sd_data.v
│      ├─sd_init.v
│      ├─sd_ram.v
│      ├─sd_read.v
│      ├─sd_write.v
│      ├─seg7x16.v
│      ├─topcpu.v
│      ├─topddr.v
│      ├─topsd.v
│      ├─topthree.v
│      └─Writeback.v
```
---

## Defenders
The repo is currently owned by https://github.com/teamwong111 maintain

If I have infringement or you have any questions, please open an issue or contact me by email wungjz1@gmail.com

---

## License
[MIT](https://github.com/teamwong111/System-Structure-Course/blob/main/LICENSE)

---