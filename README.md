# SRIO 收发控制器 FPGA测试工程
## 测试环境
 - FPGA型号：XC7VX690TFFG1927-2
 - Vivado版本：2019.2
## 文件目录
 - ip_repo
   - srio_rxc_1.0：SRIO接收控制器
   - srio_trc_1.0：SRIO收发控制器（接收功能未实现）
 - src
   - bd：用于建立Block Design的Tcl脚本
   - constrs：引脚、时序约束文件
 - build.tcl
   - 工程建立脚本
 - build.bat
   - 调用build.tcl，建立工程
## 工程重建方法：
 - 双击build.bat

## 系统设计
 - [AXI Memory-Mapped SRIO收发控制器](https://blog.csdn.net/qq_35787848/article/details/122036299)