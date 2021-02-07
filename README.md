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

  ```
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apple/tensorflow_macos/master/scripts/download_and_install.sh)"
  ```

  This will verify your system, ask you for confirmation, then create a virtual environment (https://docs.python.org/3.8/tutorial/venv.html) with TensorFlow for macOS installed.

- Alternatively, download the archive file from the [releases](https://github.com/apple/tensorflow_macos/releases). The archive contains an installation script, accelerated versions of TensorFlow, TensorFlow Addons, and needed dependencies.

#### Installation on Conda

This pre-release version supports installation and testing using the Python from Xcode Command Line Tools. See [#153](https://github.com/apple/tensorflow_macos/issues/153) for more information on installation in a Conda environment.

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

  ```
  # Import mlcompute module to use the optional set_mlc_device API for device selection with ML Compute.
  from tensorflow.python.compiler.mlcompute import mlcompute

  # Select CPU device.
  mlcompute.set_mlc_device(device_name='cpu') # Available options are 'cpu', 'gpu', and ‘any'.
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


##### Eager mode

Unlike graph mode, logging in eager mode is controlled by `TF_CPP_MIN_VLOG_LEVEL`. The following is the list of information that is logged in eager mode:

- The buffer pointer and shape of input/output tensor.
- The key for associating the tensor’s buffer to built the `MLCTraining` or `MLCInference` graph. This key is used to retrieve the graph and run a backward pass or an optimizer update.
- The weight tensor format.
- Caching statistics, such as insertions and deletions.


##### Tips for debugging

- Larger models being trained on the GPU may use more memory than is available, resulting in paging.  If this happens, try decreasing the batch size or the number of layers.
- TensorFlow is multi-threaded, which means that different TensorFlow operations, such as` MLCSubgraphOp`, can execute concurrently. As a result, there may be overlapping logging information. To avoid this during the debugging process, set TensorFlow to execute operators sequentially by setting the number of threads to 1 (see [`tf.config.threading.set_inter_op_parallelism_threads`](https://www.tensorflow.org/api_docs/python/tf/config/threading/set_inter_op_parallelism_threads)).

##### Additional tips for debugging in eager mode:

- To find information about a specific tensor in the log, search for its buffer pointer in the log. If the tensor is defined by an operation that ML Compute does not support, you will need to cast it to `size_t` and search for it in log entries with the pattern `MemoryLogTensorAllocation ... true ptr: <(size_t)ptr>`.  You may also need to modify the `OpKernelContext::input()` to print out the input pointer so that you can see the entire use-def chain in the log.
- You may disable the conversion of any eager operation to ML Compute by using `TF_DISABLE_MLC_EAGER=“;Op1;Op2;...”`. The gradient op may also need to be disabled by modifying  the file `$PYTHONHOME/site-packages/tensorflow/python/ops/_grad.py` (this avoids TensorFlow recompilation).
- To initialize allocated memory with a specific value, use `TF_MLC_ALLOCATOR_INIT_VALUE=<init-value>`.

