# buptLab-network

这个仓库包含了北京邮电大学 2024-2025 秋季学期《计算机网络技术实践》课程实验的各项重要内容：

- 实验三——动态路由协议——的相关代码和报告；

## 使用说明

### 环境配置

实验在 Windows 下进行，使用前需要安装 Windows 可选功能 Telnet Client，并且安装 PowerShell。

### 启动模拟系统

切换到对应目录下，执行脚本 `start.ps1` 即可启动模拟器。

例如，启动实验三 RIP 协议的模拟器，可以在依次执行命令如下。

```sh
cd lab3-routing/task1-rip
./start.ps1
```

### 网络自动化配置

切换到对应目录下，执行脚本 `configure.ps1` 即可自动配置网络。

例如，自动配置实验三 RIP 协议的网络，可以在依次执行命令如下。

```sh
cd lab3-routing/task1-rip
./configure.ps1
```

## 目录结构

```
.
├── LICENSE                # 项目许可证文件
├── README.md              # 项目描述和说明的自述文件
├── requirements.txt       # Python 脚本依赖
├── lab<n>-<lab_name>                   # 实验相关文件目录
│   └── <category><id>-<name>           # 实验子任务或思考题相关文件
│       ├── configuration
│       │   └── <device_name>.txt       # 设备自动化配置命令文件
│       ├── data                        # 抓包数据
│       │   ├── *.cap
│       │   └── *.pcapng
│       ├── configure.ps1               # 网络自动化配置脚本
│       └── start.ps1                   # 模拟系统启动脚本
└── util
    ├── util.ps1                        # PowerShell 工具脚本
    └── auto.py                         # 网络设备自动配置程序
```
