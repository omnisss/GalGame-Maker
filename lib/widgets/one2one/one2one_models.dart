//立绘图片
class SpriteVariant {
  final String variant; // 动作差分 1 / 2 / 3
  final String? note; //备注
  final String? file; // 已保存后的相对路径（例如：assets/sprites/happy/高兴-1.png）
  final String? pickedPath; // 上传选择但尚未保存时的源文件绝对路径（例如：C:\xxx\1.png /storage/.../1.png）

  const SpriteVariant({
    required this.variant,
    this.note,
    this.file,
    this.pickedPath,
  });

  SpriteVariant copyWith({
    String? variant,
    String? note,
    String? file,
    String? pickedPath,
  }) {
    return SpriteVariant(
      variant: variant ?? this.variant,
      note: note ?? this.note,
      file: file ?? this.file,
      pickedPath: pickedPath ?? this.pickedPath,
    );
  }
}

class SpriteCell {
  final String outfit;   // 纵轴，衣服
  final String emotion;  // 横轴，表情
  final List<SpriteVariant> variants; //动作差分序号

  const SpriteCell({
    required this.outfit,
    required this.emotion,
    required this.variants,
  });

  SpriteCell copyWith({
    String? outfit,
    String? emotion,
    List<SpriteVariant>? variants,
  }) {
    return SpriteCell(
      outfit: outfit ?? this.outfit,
      emotion: emotion ?? this.emotion,
      variants: variants ?? this.variants,
    );
  }
}
//立绘图片
/*class SpriteFrame {
  final String title;    // 文件名/显示名（例如：高兴-1）
  final String? note;    // 备注（占位）

  /// 已保存后的相对路径（例如：assets/sprites/happy/高兴-1.png）
  final String? file;

  /// 上传选择但尚未保存时的源文件绝对路径（例如：C:\xxx\1.png /storage/.../1.png）
  final String? pickedPath;

  const SpriteFrame({
    required this.title,
    this.note,
    this.file,
    this.pickedPath,
  });

  SpriteFrame copyWith({
    String? title,
    String? note,
    String? file,
    String? pickedPath,
  }) {
    return SpriteFrame(
      title: title ?? this.title,
      note: note ?? this.note,
      file: file ?? this.file,
      pickedPath: pickedPath ?? this.pickedPath,
    );
  }
}

//立绘分类
class SpriteFolder {
  final String title;      // 文件夹显示名（例如：高兴）
  final List<SpriteFrame> frames;

  const SpriteFolder({
    required this.title,
    required this.frames,
  });

  SpriteFolder copyWith({String? title, List<SpriteFrame>? frames}) {
    return SpriteFolder(
      title: title ?? this.title,
      frames: frames ?? this.frames,
    );
  }
}*/

//背景图片
class BackgroundVariant {
  final String title;  // 例如：白天 / 黄昏 / 晚上
  final String? note;

  /// 已保存后的相对路径（例如：assets/backgrounds/classroom/day.jpg）
  final String? file;

  /// 上传选择但尚未保存时的源文件绝对路径
  final String? pickedPath;

  const BackgroundVariant({
    required this.title,
    this.note,
    this.file,
    this.pickedPath,
  });

  BackgroundVariant copyWith({
    String? title,
    String? note,
    String? file,
    String? pickedPath,
  }) {
    return BackgroundVariant(
      title: title ?? this.title,
      note: note ?? this.note,
      file: file ?? this.file,
      pickedPath: pickedPath ?? this.pickedPath,
    );
  }
}

//背景分类
class BackgroundFolder {
  final String title;     // 显示名（教室）
  final List<BackgroundVariant> variants;

  const BackgroundFolder({
    required this.title,
    required this.variants,
  });

  BackgroundFolder copyWith({String? title, List<BackgroundVariant>? variants}) {
    return BackgroundFolder(
      title: title ?? this.title,
      variants: variants ?? this.variants,
    );
  }
}