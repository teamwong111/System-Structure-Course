# System-Structure-Course
这是我在同济大学计算机系统结构课程（2020）的大作业

---

## 目录
- 简介
- 项目目录结构
- 维护者
- License

---

## 简介
本仓库为包含2020年同济大学计算机系统结构课程的三个大作业：
1. 静态流水线CPU
2. 动态流水线CPU
3. 三级存储CPU

---

## 项目目录结构
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

## 维护者

该仓库目前的维护者为https://github.com/teamwong111

如有侵权或其他问题请提出Issue，或者通过邮件联系wungjz1@gmail.com

---

## License
[MIT](https://github.com/teamwong111/System-Structure-Course/blob/main/LICENSE)

---