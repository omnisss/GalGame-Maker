class Friend {
  /// 服务器返回：id
  final int id;

  /// 服务器返回：account（例如 "AI_001"）
  //final String account;

  /// 服务器返回：username（展示名，例如 "美咕噜"）
  final String username;

  /// 服务器返回：avatar_url（例如 "avatar/ai_001.png"）
  final String avatarUrl;

  /// 可选字段（不重要的可以忽视，但留着以后扩展方便）
  /*final String? signature;
  final int? gender;
  final String? region;
  final int? grade;

  /// 路径类字段（目前前端可不用）
  final String? prompt;
  final String? memory;*/

  const Friend({
    required this.id,
    //required this.account,
    required this.username,
    required this.avatarUrl,
    /*this.signature,
    this.gender,
    this.region,
    this.grade,
    this.prompt,
    this.memory,*/
  });

  /// 兼容后端返回 key 命名（snake_case）
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: (json['id'] as num).toInt(),
      //account: (json['account'] ?? '') as String,
      username: (json['user_name'] ?? '') as String,
      avatarUrl: (json['avatar_url'] ?? '') as String,
      /*signature: json['signature'] as String?,
      gender: (json['gender'] as num?)?.toInt(),
      region: json['region'] as String?,
      grade: (json['grade'] as num?)?.toInt(),
      prompt: json['prompt'] as String?, // 没有就 null
      memory: json['memory'] as String?, // 没有就 null*/
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      //'account': account,
      'username': username,
      'avatar_url': avatarUrl,
      /*'signature': signature,
      'gender': gender,
      'region': region,
      'grade': grade,
      'prompt': prompt,
      'memory': memory,*/
    };
  }

  /// UI 里常用：显示名
  //String get displayName => username.isNotEmpty ? username : account;
  String get displayName => username;

  /// 如果签名是空白的，就显示一个空格（保持布局一致）
  /*String get displaySignature {
    final s = (signature ?? '').trim();
    return s.isEmpty ? ' ' : s;
  }*/
}
