import 'package:flutter/material.dart';
import '../../domain/entities/character_sprite.dart';

/// 도트 스타일 캐릭터를 그리는 CustomPainter
/// 
/// 레이어 기반으로 캐릭터(베이스) + 의상(레이어)을 합성
class CharacterPainter extends CustomPainter {
  /// 캐릭터 스프라이트 데이터
  final CharacterSprite sprite;
  
  /// 픽셀 크기 (도트 하나의 크기)
  final double pixelSize;
  
  /// 배경색 (null이면 투명)
  final Color? backgroundColor;

  CharacterPainter({
    required this.sprite,
    this.pixelSize = 4.0,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그리기
    if (backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor!,
      );
    }

    // 캔버스 중앙 정렬을 위한 오프셋 계산
    final characterWidth = 16 * pixelSize;  // 16픽셀 너비
    final characterHeight = 24 * pixelSize; // 24픽셀 높이
    final offsetX = (size.width - characterWidth) / 2;
    final offsetY = (size.height - characterHeight) / 2;

    // 레이어 순서대로 그리기
    _drawBaseCharacter(canvas, offsetX, offsetY);
    _drawBody(canvas, offsetX, offsetY);
    _drawLegs(canvas, offsetX, offsetY);
    _drawHead(canvas, offsetX, offsetY);
  }

  /// 기본 캐릭터 (피부, 얼굴) 그리기
  void _drawBaseCharacter(Canvas canvas, double offsetX, double offsetY) {
    final skinPaint = Paint()..color = sprite.skinColor;
    final hairPaint = Paint()..color = const Color(0xFF5D4037); // 갈색 머리
    final eyePaint = Paint()..color = const Color(0xFF212121); // 검은 눈
    
    // 머리 (원형)
    // 픽셀 좌표: (4,0) ~ (12,8) - 8x8 영역
    for (int y = 1; y <= 7; y++) {
      for (int x = 4; x <= 11; x++) {
        // 둥근 머리 모양
        if (y == 1 && (x < 6 || x > 9)) continue;
        if (y == 7 && (x < 5 || x > 10)) continue;
        _drawPixel(canvas, offsetX, offsetY, x, y, skinPaint);
      }
    }
    
    // 머리카락 (상단)
    for (int x = 5; x <= 10; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 0, hairPaint);
    }
    for (int x = 4; x <= 11; x++) {
      if (x == 4 || x == 11) {
        _drawPixel(canvas, offsetX, offsetY, x, 1, hairPaint);
      }
    }
    
    // 눈
    _drawPixel(canvas, offsetX, offsetY, 6, 4, eyePaint);
    _drawPixel(canvas, offsetX, offsetY, 9, 4, eyePaint);
    
    // 목
    _drawPixel(canvas, offsetX, offsetY, 7, 8, skinPaint);
    _drawPixel(canvas, offsetX, offsetY, 8, 8, skinPaint);
    
    // 팔 (피부 - 기본 티셔츠 없을 때)
    if (sprite.bodyItemId == null) {
      for (int y = 9; y <= 14; y++) {
        _drawPixel(canvas, offsetX, offsetY, 3, y, skinPaint);
        _drawPixel(canvas, offsetX, offsetY, 12, y, skinPaint);
      }
    }
    
    // 손
    _drawPixel(canvas, offsetX, offsetY, 3, 15, skinPaint);
    _drawPixel(canvas, offsetX, offsetY, 12, 15, skinPaint);
  }

  /// 상체 의상 그리기
  void _drawBody(Canvas canvas, double offsetX, double offsetY) {
    final itemId = sprite.bodyItemId;
    if (itemId == null) {
      // 기본 티셔츠
      _drawDefaultBody(canvas, offsetX, offsetY);
      return;
    }

    final spriteData = ItemSpriteRegistry.getSprite(itemId);
    if (spriteData == null) {
      _drawDefaultBody(canvas, offsetX, offsetY);
      return;
    }

    switch (spriteData.spriteType) {
      case SpriteType.woodTshirt:
        _drawWoodTshirt(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.forestVest:
        _drawForestVest(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.ancientArmor:
        _drawAncientArmor(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        _drawDefaultBody(canvas, offsetX, offsetY);
    }
  }

  /// 기본 티셔츠
  void _drawDefaultBody(Canvas canvas, double offsetX, double offsetY) {
    final paint = Paint()..color = const Color(0xFF9E9E9E); // 회색
    
    // 몸통 (9~15 행)
    for (int y = 9; y <= 15; y++) {
      for (int x = 4; x <= 11; x++) {
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 어깨/팔
    for (int y = 9; y <= 14; y++) {
      _drawPixel(canvas, offsetX, offsetY, 3, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 12, y, paint);
    }
  }

  /// 나무 티셔츠
  void _drawWoodTshirt(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    
    // 몸통
    for (int y = 9; y <= 15; y++) {
      for (int x = 4; x <= 11; x++) {
        // 나무결 패턴
        final paint = (x + y) % 3 == 0 ? secondary : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 어깨/팔
    for (int y = 9; y <= 14; y++) {
      _drawPixel(canvas, offsetX, offsetY, 3, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 12, y, primary);
    }
  }

  /// 숲의 조끼
  void _drawForestVest(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final accent = Paint()..color = data.accentColor ?? data.primaryColor;
    
    // 몸통
    for (int y = 9; y <= 15; y++) {
      for (int x = 4; x <= 11; x++) {
        if (x == 4 || x == 11) {
          // 가장자리 - 악센트
          _drawPixel(canvas, offsetX, offsetY, x, y, accent);
        } else if (x == 7 || x == 8) {
          // 중앙 - 보조색
          _drawPixel(canvas, offsetX, offsetY, x, y, secondary);
        } else {
          _drawPixel(canvas, offsetX, offsetY, x, y, primary);
        }
      }
    }
    // 팔 (민소매라 피부색)
    final skinPaint = Paint()..color = sprite.skinColor;
    for (int y = 9; y <= 14; y++) {
      _drawPixel(canvas, offsetX, offsetY, 3, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 12, y, skinPaint);
    }
  }

  /// 고대 나무 갑옷
  void _drawAncientArmor(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF4CAF50);
    
    // 몸통 (갑옷 패턴)
    for (int y = 9; y <= 15; y++) {
      for (int x = 4; x <= 11; x++) {
        // 갑옷 문양 패턴
        if ((x == 7 || x == 8) && (y == 11 || y == 12)) {
          _drawPixel(canvas, offsetX, offsetY, x, y, accent); // 중앙 문양
        } else if (y == 9 || y == 15) {
          _drawPixel(canvas, offsetX, offsetY, x, y, secondary); // 상하단
        } else {
          _drawPixel(canvas, offsetX, offsetY, x, y, primary);
        }
      }
    }
    // 어깨 보호대
    for (int y = 9; y <= 11; y++) {
      _drawPixel(canvas, offsetX, offsetY, 2, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 3, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 12, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 13, y, secondary);
    }
    // 팔
    for (int y = 12; y <= 14; y++) {
      _drawPixel(canvas, offsetX, offsetY, 3, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 12, y, primary);
    }
  }

  /// 하체 의상 그리기
  void _drawLegs(Canvas canvas, double offsetX, double offsetY) {
    final itemId = sprite.legsItemId;
    if (itemId == null) {
      _drawDefaultLegs(canvas, offsetX, offsetY);
      return;
    }

    final spriteData = ItemSpriteRegistry.getSprite(itemId);
    if (spriteData == null) {
      _drawDefaultLegs(canvas, offsetX, offsetY);
      return;
    }

    switch (spriteData.spriteType) {
      case SpriteType.woodShorts:
        _drawWoodShorts(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.forestPants:
        _drawForestPants(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.ancientGreaves:
        _drawAncientGreaves(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        _drawDefaultLegs(canvas, offsetX, offsetY);
    }
  }

  /// 기본 바지
  void _drawDefaultLegs(Canvas canvas, double offsetX, double offsetY) {
    final paint = Paint()..color = const Color(0xFF616161); // 진한 회색
    final shoePaint = Paint()..color = const Color(0xFF424242);
    
    // 왼쪽 다리
    for (int y = 16; y <= 21; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 6, y, paint);
    }
    // 오른쪽 다리
    for (int y = 16; y <= 21; y++) {
      _drawPixel(canvas, offsetX, offsetY, 9, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 10, y, paint);
    }
    // 신발
    for (int x = 4; x <= 7; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
    for (int x = 8; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
  }

  /// 나무 반바지
  void _drawWoodShorts(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final skinPaint = Paint()..color = sprite.skinColor;
    final shoePaint = Paint()..color = const Color(0xFF8D6E63);
    
    // 반바지 (짧은 바지)
    for (int y = 16; y <= 18; y++) {
      for (int x = 5; x <= 10; x++) {
        if (x == 7 || x == 8) continue; // 가운데 틈
        final paint = (x + y) % 2 == 0 ? secondary : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 다리 (피부)
    for (int y = 19; y <= 21; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 6, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 9, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 10, y, skinPaint);
    }
    // 신발
    for (int x = 4; x <= 7; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
    for (int x = 8; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
  }

  /// 숲의 바지
  void _drawForestPants(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final shoePaint = Paint()..color = const Color(0xFF5D4037);
    
    // 바지
    for (int y = 16; y <= 21; y++) {
      // 왼쪽 다리
      _drawPixel(canvas, offsetX, offsetY, 5, y, y % 2 == 0 ? primary : secondary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, primary);
      // 오른쪽 다리
      _drawPixel(canvas, offsetX, offsetY, 9, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 10, y, y % 2 == 0 ? primary : secondary);
    }
    // 신발
    for (int x = 4; x <= 7; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
    for (int x = 8; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
  }

  /// 고대 나무 각반
  void _drawAncientGreaves(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    final shoePaint = Paint()..color = const Color(0xFF3E2723);
    
    // 각반 (갑옷 바지)
    for (int y = 16; y <= 21; y++) {
      // 왼쪽 다리
      _drawPixel(canvas, offsetX, offsetY, 4, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 5, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, y == 18 ? accent : primary);
      _drawPixel(canvas, offsetX, offsetY, 7, y, secondary);
      // 오른쪽 다리
      _drawPixel(canvas, offsetX, offsetY, 8, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 9, y, y == 18 ? accent : primary);
      _drawPixel(canvas, offsetX, offsetY, 10, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 11, y, secondary);
    }
    // 부츠
    for (int x = 3; x <= 7; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
    for (int x = 8; x <= 12; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, shoePaint);
      _drawPixel(canvas, offsetX, offsetY, x, 23, shoePaint);
    }
  }

  /// 머리 장식 그리기
  void _drawHead(Canvas canvas, double offsetX, double offsetY) {
    final itemId = sprite.headItemId;
    if (itemId == null) return;

    final spriteData = ItemSpriteRegistry.getSprite(itemId);
    if (spriteData == null) return;

    switch (spriteData.spriteType) {
      case SpriteType.leafBand:
        _drawLeafBand(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.woodHat:
        _drawWoodHat(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.logCrown:
        _drawLogCrown(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.goldenCrown:
        _drawGoldenCrown(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        break;
    }
  }

  /// 나뭇잎 머리띠
  void _drawLeafBand(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    
    // 머리띠 밴드
    for (int x = 4; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 1, secondary);
    }
    // 나뭇잎 장식
    _drawPixel(canvas, offsetX, offsetY, 6, 0, primary);
    _drawPixel(canvas, offsetX, offsetY, 7, -1, primary);
    _drawPixel(canvas, offsetX, offsetY, 8, 0, primary);
    _drawPixel(canvas, offsetX, offsetY, 9, -1, primary);
  }

  /// 나무 모자
  void _drawWoodHat(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    
    // 모자 챙
    for (int x = 2; x <= 13; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 1, secondary);
    }
    // 모자 본체
    for (int x = 4; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 0, primary);
      _drawPixel(canvas, offsetX, offsetY, x, -1, primary);
    }
    for (int x = 5; x <= 10; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, -2, primary);
    }
  }

  /// 통나무 왕관
  void _drawLogCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    
    // 왕관 베이스
    for (int x = 4; x <= 11; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 0, primary);
    }
    // 왕관 뾰족한 부분
    _drawPixel(canvas, offsetX, offsetY, 5, -1, secondary);
    _drawPixel(canvas, offsetX, offsetY, 7, -1, secondary);
    _drawPixel(canvas, offsetX, offsetY, 8, -1, secondary);
    _drawPixel(canvas, offsetX, offsetY, 10, -1, secondary);
    
    _drawPixel(canvas, offsetX, offsetY, 5, -2, primary);
    _drawPixel(canvas, offsetX, offsetY, 7, -2, primary);
    _drawPixel(canvas, offsetX, offsetY, 8, -2, primary);
    _drawPixel(canvas, offsetX, offsetY, 10, -2, primary);
    
    // 보석 장식
    _drawPixel(canvas, offsetX, offsetY, 7, -1, accent);
    _drawPixel(canvas, offsetX, offsetY, 8, -1, accent);
  }

  /// 황금 통나무 왕관
  void _drawGoldenCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? data.primaryColor;
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFF5722);
    
    // 왕관 베이스 (더 화려하게)
    for (int x = 3; x <= 12; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 0, primary);
    }
    // 왕관 뾰족한 부분 (5개)
    for (int i = 0; i < 5; i++) {
      final x = 4 + i * 2;
      _drawPixel(canvas, offsetX, offsetY, x, -1, secondary);
      _drawPixel(canvas, offsetX, offsetY, x, -2, primary);
      _drawPixel(canvas, offsetX, offsetY, x, -3, secondary);
    }
    // 중앙 보석 (큰 보석)
    _drawPixel(canvas, offsetX, offsetY, 7, -2, accent);
    _drawPixel(canvas, offsetX, offsetY, 8, -2, accent);
    _drawPixel(canvas, offsetX, offsetY, 7, -3, accent);
    _drawPixel(canvas, offsetX, offsetY, 8, -3, accent);
    
    // 작은 보석들
    _drawPixel(canvas, offsetX, offsetY, 5, -2, Paint()..color = const Color(0xFF2196F3)); // 파란 보석
    _drawPixel(canvas, offsetX, offsetY, 10, -2, Paint()..color = const Color(0xFF4CAF50)); // 녹색 보석
  }

  /// 단일 픽셀 그리기
  void _drawPixel(Canvas canvas, double offsetX, double offsetY, int x, int y, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(
        offsetX + x * pixelSize,
        offsetY + y * pixelSize,
        pixelSize,
        pixelSize,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return sprite != oldDelegate.sprite ||
        pixelSize != oldDelegate.pixelSize ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

