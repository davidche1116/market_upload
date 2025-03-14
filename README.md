# 应用市场上传工具（Flutter编写）

将APK文件（32位、64位）上传到华为、荣耀、VIVO、OPPO、小米应用市场，并配置更新文案，选择上架时间。

## 重要说明

解析APK文件需要用到Android SDK目录。生效优先级从高到低依次为：
* 手动配置：可手动配置Android SDK目录（界面右上角设置——选择/输入目录——保存）
* 系统环境变量：系统自动从环境变量ANDROID_SDK_ROOT或ANDROID_HOME获取Android SDK目录
* 代码写死默认：lib/utils/apk_util.dart代码已有目录为：`C:/Users/Administrator/AppData/Local/Android/Sdk`；MacOS：`/Users/cechds/Library/Android/sdk`

## 界面图
![image](screenshot/p1.jpg) 
