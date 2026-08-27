// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '服务管理器';

  @override
  String get services => '服务';

  @override
  String get settings => '设置';

  @override
  String get addService => '添加服务';

  @override
  String get editService => '编辑服务';

  @override
  String get deleteService => '删除服务';

  @override
  String get noServices => '暂无服务';

  @override
  String get noServicesDescription => '添加本地程序后即可在这里管理。';

  @override
  String get selectService => '选择一个服务';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get restart => '重启';

  @override
  String get startAll => '全部启动';

  @override
  String get stopAll => '全部停止';

  @override
  String get open => '打开';

  @override
  String get exit => '退出';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get name => '名称';

  @override
  String get executable => '可执行程序';

  @override
  String get browse => '浏览';

  @override
  String get arguments => '参数';

  @override
  String get argumentsHint => '每行一个参数';

  @override
  String get workingDirectory => '工作目录';

  @override
  String get environment => '环境变量';

  @override
  String get environmentHint => '每行一个 KEY=VALUE';

  @override
  String get stopExecutable => '停止程序';

  @override
  String get stopArguments => '停止参数';

  @override
  String get startAutomatically => '随服务管理器启动';

  @override
  String get restartAutomatically => '意外退出后自动重启';

  @override
  String get stopTimeout => '停止超时';

  @override
  String get seconds => '秒';

  @override
  String get status => '状态';

  @override
  String get pid => 'PID';

  @override
  String get startedAt => '启动时间';

  @override
  String get exitCode => '退出码';

  @override
  String get logs => '日志';

  @override
  String get clearLogs => '清空';

  @override
  String get openLogFolder => '打开目录';

  @override
  String get pauseLogs => '暂停';

  @override
  String get resumeLogs => '继续';

  @override
  String get searchLogs => '搜索日志';

  @override
  String get followLogs => '跟随输出';

  @override
  String get noLogs => '暂无日志';

  @override
  String get launchAtLogin => '登录后启动';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '跟随系统';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get appearance => '外观';

  @override
  String get behavior => '行为';

  @override
  String get logRetention => '日志保留';

  @override
  String get logRetentionDescription => '每个服务保留 5 个 5 MiB 文件';

  @override
  String deleteServiceTitle({required String name}) {
    return '删除 $name？';
  }

  @override
  String get deleteServiceMessage => '该服务的配置和日志将被移除。';

  @override
  String get exitTitle => '退出服务管理器？';

  @override
  String get exitMessage => '退出前将停止所有运行中的服务。';

  @override
  String get stopAllTitle => '停止全部服务？';

  @override
  String get stopAllMessage => '所有运行中的服务都将停止。';

  @override
  String get requiredField => '必填';

  @override
  String get invalidEnvironment => '请在每行使用 KEY=VALUE 格式';

  @override
  String get executableNotFound => '可执行程序不存在';

  @override
  String get directoryNotFound => '工作目录不存在';

  @override
  String saveFailed({required String error}) {
    return '无法保存配置：$error';
  }

  @override
  String operationFailed({required String error}) {
    return '操作失败：$error';
  }

  @override
  String configurationRecovered({required String path}) {
    return '配置文件已损坏并移动到 $path。';
  }

  @override
  String runningCount({required int running}) {
    return '$running 个服务正在运行';
  }

  @override
  String get statusStopped => '已停止';

  @override
  String get statusStarting => '启动中';

  @override
  String get statusRunning => '运行中';

  @override
  String get statusStopping => '停止中';

  @override
  String get statusRestarting => '重启中';

  @override
  String get statusFailed => '失败';

  @override
  String get stdout => '输出';

  @override
  String get stderr => '错误';

  @override
  String get manager => '管理器';

  @override
  String get serviceNameRequired => '请输入服务名称';

  @override
  String get plainTextEnvironmentWarning => '环境变量值将以明文保存。';

  @override
  String unexpectedExit({required int code}) {
    return '进程意外退出，退出码 $code。';
  }

  @override
  String get restartLimitReached => '已达到自动重启次数上限。';

  @override
  String launchFailed({required String error}) {
    return '启动失败：$error';
  }
}
