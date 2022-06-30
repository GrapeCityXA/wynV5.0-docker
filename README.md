# wynV5.0-docker
wynV5.0-docker
### 导出自定义的文档和配置。
1、首先，使用Wyn官方提供的docker镜像来创建一个自己的docker容器。例如：
```
sudo docker run –name wyn -p 51980:51980 -d grapecitycn/wyn-enterprise:5.0.00312.0/
```
2、访问docker容器中运行的Wyn应用程序。此时，可以根据自己的需要来对Wyn系统进行配置，比如替换登录页面的背景图片和LOGO，替换系统左上角显示的LOGO，以及替换浏览器tag页上面显示的LOGO。还可以根据自己的需要创建一些示例文档。

3、 从Admin Portal中导出你需要的文档以及配置。
### 制作docker镜像。
1、准备一台Linux机器，把文件夹custom-wyn拷贝到这台机器上面去。

2、把步骤1.3中导出的压缩文件重命名为sample_files.zip，并拷贝到目录
```custom-wyn/sample_files```下面。

3、如果需要在自定义的docker镜像中内置字体，请把准备好的字体文件拷贝到目录```custom-wyn/custom_fonts```下。

4、根据自己的需要，修改dockerfile文件中docker镜像wyn-enterprise的tag名称。
5、参照脚本文件push-docker-image.sh中的内容，制作并且上传docker镜像到docker仓库中。
### 拉取docker镜像进行验证。
1、	拉取步骤2中创建好的docker镜像，并使用该镜像创建一个docker容器。
2、	访问该docker容器中运行的Wyn应用并进行验证。
