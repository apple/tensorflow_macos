## 针对 Mac 优化的 TensorFlow 和 TensorFlow Addons

### 简介

这个预览版为 macOS 11.0+ 提供了硬件加速的 TensorFlow 和 TensorFlow Addons。通过 Apple 的 [ML Compute](https://developer.apple.com/documentation/mlcompute) 框架，M1 Mac 和 Intel 芯片的 Mac 都支持了原生硬件加速。

### 当前版本

- 0.1-alpha3

### 支持版本

- TensorFlow r2.4rc0
- TensorFlow Addons 0.11.2

### 依赖

- macOS 11.0+
- Python 3.8（搭载 M1 Mac 芯片的 Mac 需要从[Xcode命令行工具](https://developer.apple.com/download/more/?=command%20line%20tools)下载）。

### 安装

包含 Python 安装包和安装脚本的压缩文件可以从 [releases](https://github.com/apple/tensorflow_macos/releases) 下载。

- 您想快速体验这个版本的 TensorFlow，复制并粘贴以下内容到终端：

  ```shell
  % /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apple/tensorflow_macos/master/scripts/download_and_install.sh)"
  ```

  这将验证您的系统并要求您进行确认，然后创建一个安装了 TensorFlow macOS 的[虚拟环境](https://docs.python.org/3.8/tutorial/venv.html)。

- 或者，从 [release](https://github.com/apple/tensorflow_macos/releases) 下载压缩文件。压缩文件中包含一个安装脚本，其中包括加速版本的 TensorFlow ，TensorFlow Addons ，以及其他所需的依赖项。

  ```shell
  % curl -fLO https://github.com/apple/tensorflow_macos/releases/download/v0.1alpha2/tensorflow_macos-${VERSION}.tar.gz
  % tar xvzf tensorflow_macos-${VERSION}.tar
  % cd tensorflow_macos
  % ./install_venv.sh --prompt
  ```

#### 在Conda上安装

TensorFlow 预览版支持使用 Xcode 命令行工具中的 Python 安装和测试.。更多在 Conda 环境中安装的信息，请您参阅[#153](https://github.com/apple/tensorflow_macos/issues/153)。

#### 注意

对于搭载 M1 Mac ，以下依赖包目前不可用：

- SciPy 和依赖包
- 服务器/客户端的 TensorBoard 

在虚拟环境中安装 pip 软件包，您可能需要指定`--target`，如下所示：

```shell
% pip install --upgrade -t "${VIRTUAL_ENV}/lib/python3.8/site-packages/" PACKAGE_NAME
```

### 问题和反馈

请通过 [GitHub Issues](https://github.com/apple/tensorflow_macos/issues) 提交新功能请求和报告问题。

### 更多信息

#### 指定硬件设备(可选)

首先，使用 ML Compute 作为 TensorFlow 和 TensorFlow Addons 的后端，是不需要对现有的 TensorFlow 脚本做任何更改。

有一个可选的 ML Compute 硬件设备选择API `mlcompute.set_mlc_device(device_name='any')`。其中，`device_name`的默认值是`'any'`，这意味着 ML Compute 将在您的系统上选择最佳可用硬件设备，包括在多 GPU 上配置多 GPU 训练。其他可用参数有`'cpu'` 和`'gpu'` 。需要您注意，在即时执行模式下， ML Compute 将使用CPU。 如果您想选择 CPU ，你可以这样做：

  ```python
# 导入mlcompute模块, 使用可选的set_mlc_device API来使用ML Compute进行硬件设备选择.
from tensorflow.python.compiler.mlcompute import mlcompute

# 选择CPU.
mlcompute.set_mlc_device(device_name='cpu')  # 可用选项为'cpu', 'gpu'和'any'.
  ```

#### 不支持的 TensorFlow 特性

以下 TensorFlow 特性目前在这个复刻暂不支持：

- [tf.vectorized_map(向量化映射)](https://www.tensorflow.org/api_docs/python/tf/vectorized_map)
- [高阶梯度](https://www.tensorflow.org/guide/advanced_autodiff#higher-order_gradients)
- 雅可比矢量积 （又名 [前向传播](https://www.tensorflow.org/api_docs/python/tf/autodiff/ForwardAccumulator)）

#### 日志和调试

##### 图执行模式

日志记录了许多关于 ML Compute 优化 TensorFlow 模型时产生的信息。在执行模型脚本时，通过设置环境变量`TF_MLC_LOGGING=1` 来显示日志。如下是图执行模式记录的日志信息列表：

- ML Compute 使用的硬件设备。
- 不使用 ML Compute 的原始 TensorFlow 计算图。
- 将 TensorFlow 操作替换为 ML Compute 后的 TensorFlow 计算图。
    - 在计算图中查找 MLCSubgraphOp 节点。这些节点中的每一个结点都替换了原计算图中的一个 TensorFlow 子图，并封装了子图中的所有操作。这些可以用来确定 ML Compute 正在优化哪些操作。
- 使用 ML Compute 的子图的数量以及每个子图中包含的操作的数量。
    - 如果使用 ML Compute，用更大的子图来封装大部分的原始计算图，性能将会提高。注意，对于训练过程，通常至少有两个 MLCSubgraphOp 节点（表示前向传播以及反向传播/计算梯度子图）。
- ML Compute 计算图相对应的 TensorFlow 子图。

##### 即时执行模式

不同于图执行模式，即时执行模式的日志显示由`TF_CPP_MIN_VLOG_LEVEL`控制。如下是即时执行模式记录的日志信息列表：

- 缓冲区指针和输入/输出张量的形状。
- 构建`MLCTraining` 或者`MLCInference`计算图的张量缓冲区的键值。该键值用于复现计算图，以及运行反向传播或者是更新优化器的参数。
- 格式化的权重张量。
- 保存统计日志，例如插入和删除的信息。
  
###### 翻译说明：即时执行模式，翻译自 Eager mode。该模式下不需要先构造静态计算图，而是即时执行代码，这样在研究和开发时会更加符合直觉。

##### 调试建议

- 在 GPU 上训练较大的模型可能会超出可分配的显存（搭载 Apple M1 芯片的 Mac 使用的是 UMA 内存），导致显存分页。如果发生了这样的情况，您可以尝试减小批次大小或者是模型的层数。
- TensorFlow 支持多线程，这意味着不同的 TensorFlow 操作可以并行执行，比如` MLCSubgraphOp`。但这可能会导致输出重复的日志信息，如果您不希望在调试中出现这种情况，您可以设置线程数为1让 TensorFlow 顺序执行操作（详细信息，请参阅[`tf.config.threading.set_inter_op_parallelism_threads`](https://www.tensorflow.org/api_docs/python/tf/config/threading/set_inter_op_parallelism_threads)）。
- 在即时执行模式下，您可以通过使用`TF_DISABLE_MLC_EAGER=“;Op1;Op2;...”`禁止即时执行模式下的任何操作转换成 ML Compute。您可以通过修改`$PYTHONHOME/site-packages/tensorflow/python/ops/_grad.py`文件来禁止计算梯度的操作（这样可以避免 TensorFlow 重新编译）。
- 为特定变量分配初始化的内存，请使用 `TF_MLC_ALLOCATOR_INIT_VALUE=<init-value>`。
- 设置环境变量`TF_DISABLE_MLC=1`来禁止 ML Compute 加速（例如，用于调试或验证结果）。

### 翻译人员

译者才疏学浅，学识简陋，自明译文不及原著，纵使多次勘误和推敲，但仍难表达原著精微之处。前有孺子尝甘苦，诚邀诸君续春秋。@[Lu Han](https://github.com/luhan1024) 参与翻译了前半部分 @[Steve R. Sun](https://github.com/sun1638650145) 参与翻译了后半部分，您可以通过QQ:1040256093 / 1638650145 或邮箱 luhan_1024@outlook.com / s16386510145@gmail.com 联系我们并提出改进意见。

