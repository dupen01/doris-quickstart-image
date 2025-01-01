# doris-quickstart-image
提供一个快速部署的Doris Docker镜像，只需一个单独的镜像即可快速体验Doris。


## 公开镜像
### 2.1.7 版本
registry.cn-chengdu.aliyuncs.com/duperl/doris:quickstart-2.1.7-arm64


### 3.0.3 版本
registry.cn-chengdu.aliyuncs.com/duperl/doris:quickstart-3.0.3-arm64


## 本地构建镜像
```shell
# 构建参数说明：
# VERSION：目前仅支持 2.1.7 和 3.0.3，默认 3.0.3
# JDK：如果VERSION是3.0.3，JDK必须是17，如果VERSION是2.1.7，JDK必须是8，默认17
# CPU：可选 x64 和 arm64，默认 arm64

# 示例：
docker build \
--build-arg VERSION=2.1.7 \
--build-arg JDK=8 \
--build-arg CPU=x64 \
-t <image-name:image-tag> .

docker build -t registry.cn-chengdu.aliyuncs.com/duperl/doris:quickstart-3.0.3-arm64 .
```
