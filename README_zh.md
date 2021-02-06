## Mac-optimized TensorFlow and TensorFlow Addons


### INTRODUCTION

This pre-release delivers hardware-accelerated TensorFlow and TensorFlow Addons for macOS 11.0+. Native hardware acceleration is supported on Macs with M1 and Intel-based Macs through Apple’s [ML Compute](https://developer.apple.com/documentation/mlcompute) framework.

### CURRENT RELEASE

- 0.1-alpha2

### SUPPORTED VERSIONS

- TensorFlow r2.4rc0
- TensorFlow Addons 0.11.2

### REQUIREMENTS

- macOS 11.0+
- Python 3.8, available from the [Xcode Command Line Tools](https://developer.apple.com/download/more/?=command%20line%20tools).

### INSTALLATION

An archive containing Python packages and an installation script can be downloaded from the [releases](https://github.com/apple/tensorflow_macos/releases).

#### Details

- To quickly try this out, copy and paste the following into Terminal:

  ```shell
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apple/tensorflow_macos/master/scripts/download_and_install.sh)"
  ```

  This will verify your system, ask you for confirmation, then create a virtual environment (https://docs.python.org/3.8/tutorial/venv.html) with TensorFlow for macOS installed.

- Alternatively, download the archive file from the [releases](https://github.com/apple/tensorflow_macos/releases). The archive contains an installation script, accelerated versions of TensorFlow, TensorFlow Addons, and needed dependencies.

#### Notes

For Macs with M1, the following packages are currently unavailable:

- SciPy and dependent packages
- Server/Client TensorBoard packages

### ISSUES AND FEEDBACK

Please submit feature requests or report issues via [GitHub Issues](https://github.com/apple/tensorflow_macos/issues).

### ADDITIONAL INFORMATION

#### Device Selection (Optional)

It is not necessary to make any changes to your existing TensorFlow scripts to use ML Compute as a backend for TensorFlow and TensorFlow Addons.

There is an optional `mlcompute.set_mlc_device(device_name='any')` API for ML Compute device selection. The default value for `device_name` is `'any'`, which means ML Compute will select the best available device on your system, including multiple GPUs on multi-GPU configurations. Other available options are `'cpu'` and `'gpu'`. Please note that in eager mode, ML Compute will use the CPU. For example, to choose the CPU device, you may do the following:

  ```python
# Import mlcompute module to use the optional set_mlc_device API for device selection with ML Compute.
from tensorflow.python.compiler.mlcompute import mlcompute

# Select CPU device.
mlcompute.set_mlc_device(device_name='cpu') # Available options are 'cpu', 'gpu', and 'any'.
  ```


#### Logs and Debugging

##### Graph mode

Logging provides more information about what happens when a TensorFlow model is optimized by ML Compute. Turn logging on by setting the environment variable `TF_MLC_LOGGING=1` when executing the model script. The following is the list of information that is logged in graph mode:

- Device used by ML Compute.
- Original TensorFlow graph without ML Compute.
- TensorFlow graph after TensorFlow operations have been replaced with ML Compute.
    - Look for MLCSubgraphOp nodes in this graph. Each of these nodes replaces a TensorFlow subgraph from the original graph, encapsulating all the operations in the subgraph. This, for example, can be used to determine which operations are being optimized by ML Compute.
- Number of subgraphs using ML Compute and how many operations are included in each of these subgraphs.
    - Having larger subgraphs that encapsulate big portions of the original graph usually results in better performance from ML Compute. Note that for training, there will usually be at least two MLCSubgraphOp nodes (representing forward and backward/gradient subgraphs).
- TensorFlow subgraphs that correspond to each of the ML Compute graphs.

##### Eager模式

不同于静态图模式, eager模式的日志显示由`TF_CPP_MIN_VLOG_LEVEL`控制. 如下是eager模式记录的日志信息列表: 

- 缓冲区指针和输入/输出张量的形状.
- 构建`MLCTraining` 或者`MLCInference`计算图的张量缓冲区的键值. 该键值用于复现计算图, 以及运行反向传播或者是更新优化器的参数.
- 格式化的权重张量.
- 保存统计日志, 例如插入和删除的信息.

##### 调试建议

- 在GPU上训练较大的模型可能会超出可分配的内存, 导致内存分页. 如果发生了这样的情况, 您可以尝试减小批次大小或者是模型的层数.
- TensorFlow支持多线程, 这意味着不同的TensorFlow操作可以并行执行, 比如` MLCSubgraphOp`. 但这可能会导致输出重复的日志信息, 如果您不希望在调试中出现这种情况, 您可以设置线程数为1让TensorFlow顺序执行操作(请参阅[`tf.config.threading.set_inter_op_parallelism_threads`](https://www.tensorflow.org/api_docs/python/tf/config/threading/set_inter_op_parallelism_threads)).

##### 在eager模式下调试的其他建议:

- 在日志中寻找指定张量的信息, 请您在日志中搜索张量缓冲区的指针. 如果定义了ML Compute不支持的操作, 您需要强制转换为`size_t` 类型然后在日志中搜索有`MemoryLogTensorAllocation ... true ptr: <(size_t)ptr>`的指针. 如果您想在日志中看到整个LLVM的use-def链, 您有可能需要修改函数`OpKernelContext::input()`.
- 您可以通过使用`TF_DISABLE_MLC_EAGER=“;Op1;Op2;...”`禁止任何eager模式下的操作转换成ML Compute.您可以通过修改`$PYTHONHOME/site-packages/tensorflow/python/ops/_grad.py`文件来来禁止计算梯度的操作(这样可以避免TensorFlow重新编译).
- 为特定变量分配初始化的内存, 请使用 `TF_MLC_ALLOCATOR_INIT_VALUE=<init-value>`.

