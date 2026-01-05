import 'package:flutter/material.dart';
import '../../domain/entities/character_sprite.dart';

/// 고퀄리티 도트 스타일 캐릭터를 그리는 CustomPainter
/// 
/// 32x48 픽셀 해상도로 디테일한 캐릭터 표현
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
    this.pixelSize = 3.0,
    this.backgroundColor,
  });

  // 캐릭터 크기 상수 (32x48 픽셀)
  static const int _width = 32;
  static const int _height = 48;

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
    final characterWidth = _width * pixelSize;
    final characterHeight = _height * pixelSize;
    final offsetX = (size.width - characterWidth) / 2;
    final offsetY = (size.height - characterHeight) / 2;

    // 그림자 그리기
    _drawShadow(canvas, offsetX, offsetY);
    
    // 레이어 순서대로 그리기
    _drawBaseCharacter(canvas, offsetX, offsetY);
    _drawBody(canvas, offsetX, offsetY);
    _drawLegs(canvas, offsetX, offsetY);
    _drawHead(canvas, offsetX, offsetY);
  }

  /// 그림자 그리기
  void _drawShadow(Canvas canvas, double offsetX, double offsetY) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    
    // 타원형 그림자
    for (int x = 8; x <= 23; x++) {
      for (int y = 45; y <= 47; y++) {
        if (y == 45 && (x < 10 || x > 21)) continue;
        if (y == 47 && (x < 12 || x > 19)) continue;
        _drawPixel(canvas, offsetX, offsetY, x, y, shadowPaint);
      }
    }
  }

  /// 기본 캐릭터 (피부, 얼굴, 머리카락) 그리기
  void _drawBaseCharacter(Canvas canvas, double offsetX, double offsetY) {
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    final hairPaint = Paint()..color = const Color(0xFF4E342E);
    final hairHighlight = Paint()..color = const Color(0xFF6D4C41);
    final eyePaint = Paint()..color = const Color(0xFF212121);
    final eyeWhite = Paint()..color = Colors.white;
    final mouthPaint = Paint()..color = const Color(0xFFE57373);
    final cheekPaint = Paint()..color = const Color(0xFFFFCDD2).withValues(alpha: 0.6);
    
    // === 머리 (둥근 형태) ===
    // 메인 머리 영역 (y: 4~16, x: 8~23)
    for (int y = 5; y <= 15; y++) {
      int startX = 9, endX = 22;
      if (y == 5) { startX = 11; endX = 20; }
      if (y == 6) { startX = 10; endX = 21; }
      if (y == 15) { startX = 10; endX = 21; }
      
      for (int x = startX; x <= endX; x++) {
        // 얼굴 음영
        final paint = (x <= 11 || y >= 14) ? skinShadow : skinPaint;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // === 머리카락 ===
    // 상단 머리카락
    for (int x = 10; x <= 21; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 2, hairPaint);
      _drawPixel(canvas, offsetX, offsetY, x, 3, hairPaint);
    }
    for (int x = 9; x <= 22; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, hairPaint);
    }
    // 옆머리
    for (int y = 5; y <= 8; y++) {
      _drawPixel(canvas, offsetX, offsetY, 8, y, hairPaint);
      _drawPixel(canvas, offsetX, offsetY, 9, y, y <= 6 ? hairPaint : hairHighlight);
      _drawPixel(canvas, offsetX, offsetY, 22, y, hairHighlight);
      _drawPixel(canvas, offsetX, offsetY, 23, y, hairPaint);
    }
    // 앞머리
    for (int x = 10; x <= 21; x++) {
      if (x >= 13 && x <= 18) continue; // 이마 보이게
      _drawPixel(canvas, offsetX, offsetY, x, 5, hairPaint);
    }
    // 하이라이트
    _drawPixel(canvas, offsetX, offsetY, 12, 3, hairHighlight);
    _drawPixel(canvas, offsetX, offsetY, 13, 3, hairHighlight);
    
    // === 눈 ===
    // 왼쪽 눈
    _drawPixel(canvas, offsetX, offsetY, 11, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 12, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 13, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 12, 10, eyePaint);
    _drawPixel(canvas, offsetX, offsetY, 13, 10, eyePaint);
    _drawPixel(canvas, offsetX, offsetY, 13, 9, eyePaint); // 동공
    
    // 오른쪽 눈
    _drawPixel(canvas, offsetX, offsetY, 18, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 19, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 20, 9, eyeWhite);
    _drawPixel(canvas, offsetX, offsetY, 18, 10, eyePaint);
    _drawPixel(canvas, offsetX, offsetY, 19, 10, eyePaint);
    _drawPixel(canvas, offsetX, offsetY, 18, 9, eyePaint); // 동공
    
    // === 볼터치 ===
    _drawPixel(canvas, offsetX, offsetY, 10, 11, cheekPaint);
    _drawPixel(canvas, offsetX, offsetY, 11, 11, cheekPaint);
    _drawPixel(canvas, offsetX, offsetY, 20, 11, cheekPaint);
    _drawPixel(canvas, offsetX, offsetY, 21, 11, cheekPaint);
    
    // === 입 ===
    _drawPixel(canvas, offsetX, offsetY, 15, 13, mouthPaint);
    _drawPixel(canvas, offsetX, offsetY, 16, 13, mouthPaint);
    
    // === 목 ===
    for (int y = 16; y <= 18; y++) {
      _drawPixel(canvas, offsetX, offsetY, 14, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 15, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 16, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 17, y, skinShadow);
    }
    
    // === 팔 (옷이 없을 때) ===
    if (sprite.bodyItemId == null) {
      for (int y = 19; y <= 30; y++) {
        _drawPixel(canvas, offsetX, offsetY, 6, y, skinPaint);
        _drawPixel(canvas, offsetX, offsetY, 7, y, skinShadow);
        _drawPixel(canvas, offsetX, offsetY, 24, y, skinShadow);
        _drawPixel(canvas, offsetX, offsetY, 25, y, skinPaint);
      }
    }
    
    // === 손 ===
    for (int y = 31; y <= 33; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 6, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 7, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 24, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 25, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 26, y, skinPaint);
    }
  }

  /// 상체 의상 그리기
  void _drawBody(Canvas canvas, double offsetX, double offsetY) {
    final itemId = sprite.bodyItemId;
    if (itemId == null) {
      _drawDefaultBody(canvas, offsetX, offsetY);
      return;
    }

    final spriteData = ItemSpriteRegistry.getSprite(itemId);
    if (spriteData == null) {
      _drawDefaultBody(canvas, offsetX, offsetY);
      return;
    }

    switch (spriteData.spriteType) {
      // 통나무 상체 아이템
      case SpriteType.woodTshirt:
        _drawWoodTshirt(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.forestVest:
        _drawForestVest(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.ancientArmor:
        _drawAncientArmor(canvas, offsetX, offsetY, spriteData);
        break;
      // 쇠 상체 아이템
      case SpriteType.ironTankTop:
        _drawIronTankTop(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.chainMail:
        _drawChainMail(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.plateArmor:
        _drawPlateArmor(canvas, offsetX, offsetY, spriteData);
        break;
      // 흙 상체 아이템
      case SpriteType.natureRobe:
        _drawNatureRobe(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.earthPoncho:
        _drawEarthPoncho(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        _drawDefaultBody(canvas, offsetX, offsetY);
    }
  }

  /// 기본 티셔츠
  void _drawDefaultBody(Canvas canvas, double offsetX, double offsetY) {
    final primary = Paint()..color = const Color(0xFF78909C);
    final shadow = Paint()..color = const Color(0xFF546E7A);
    final highlight = Paint()..color = const Color(0xFF90A4AE);
    
    // 몸통 (19~32 행)
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        Paint paint = primary;
        if (x <= 10 || y >= 30) paint = shadow;
        if (x >= 20 && y <= 22) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 어깨/팔
    for (int y = 19; y <= 30; y++) {
      _drawPixel(canvas, offsetX, offsetY, 6, y, shadow);
      _drawPixel(canvas, offsetX, offsetY, 7, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, shadow);
    }
    
    // 칼라
    for (int x = 13; x <= 18; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 18, highlight);
    }
  }

  /// 나무 티셔츠
  void _drawWoodTshirt(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final highlight = Paint()..color = _lighten(data.primaryColor, 0.1);
    
    // 몸통 (나무결 패턴)
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        // 나무결 패턴
        Paint paint;
        if ((x + y) % 4 == 0) {
          paint = secondary;
        } else if ((x + y) % 4 == 2 && x >= 18) {
          paint = highlight;
        } else {
          paint = primary;
        }
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 팔
    for (int y = 19; y <= 30; y++) {
      final paint = y % 3 == 0 ? secondary : primary;
      _drawPixel(canvas, offsetX, offsetY, 6, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 7, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 24, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 25, y, secondary);
    }
    
    // 나무 로고 (가슴 부분)
    final logoPaint = Paint()..color = const Color(0xFF5D4037);
    _drawPixel(canvas, offsetX, offsetY, 14, 23, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 15, 22, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 15, 23, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 15, 24, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 16, 23, logoPaint);
  }

  /// 숲의 조끼
  void _drawForestVest(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF81C784);
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    
    // 몸통 (조끼)
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        Paint paint;
        if (x <= 9 || x >= 22) {
          paint = secondary; // 가장자리
        } else if (x >= 14 && x <= 17) {
          paint = accent; // 중앙 라인
        } else {
          paint = primary;
        }
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 지퍼/버튼 디테일
    for (int y = 20; y <= 31; y += 3) {
      _drawPixel(canvas, offsetX, offsetY, 15, y, Paint()..color = const Color(0xFFFFD54F));
      _drawPixel(canvas, offsetX, offsetY, 16, y, Paint()..color = const Color(0xFFFFD54F));
    }
    
    // 팔 (민소매 - 피부 노출)
    for (int y = 19; y <= 30; y++) {
      _drawPixel(canvas, offsetX, offsetY, 6, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 7, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 24, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 25, y, skinPaint);
    }
    
    // 잎사귀 장식
    _drawPixel(canvas, offsetX, offsetY, 10, 21, accent);
    _drawPixel(canvas, offsetX, offsetY, 11, 20, accent);
    _drawPixel(canvas, offsetX, offsetY, 11, 22, accent);
  }

  /// 고대 나무 갑옷
  void _drawAncientArmor(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.25);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF4CAF50);
    final gold = Paint()..color = const Color(0xFFFFD700);
    
    // 갑옷 몸통
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        Paint paint = primary;
        // 갑옷 판금 패턴
        if (y == 19 || y == 25 || y == 32) paint = secondary;
        if (x == 8 || x == 23) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 중앙 문양 (나무 정령)
    for (int y = 22; y <= 28; y++) {
      _drawPixel(canvas, offsetX, offsetY, 15, y, accent);
      _drawPixel(canvas, offsetX, offsetY, 16, y, accent);
    }
    _drawPixel(canvas, offsetX, offsetY, 14, 24, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 24, accent);
    _drawPixel(canvas, offsetX, offsetY, 14, 26, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 26, accent);
    
    // 금색 테두리
    for (int y = 20; y <= 31; y += 5) {
      for (int x = 9; x <= 22; x++) {
        _drawPixel(canvas, offsetX, offsetY, x, y, gold);
      }
    }
    
    // 어깨 보호대
    for (int y = 17; y <= 22; y++) {
      _drawPixel(canvas, offsetX, offsetY, 4, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 5, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 7, y, secondary);
      
      _drawPixel(canvas, offsetX, offsetY, 24, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 26, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 27, y, secondary);
    }
    // 어깨 스파이크
    _drawPixel(canvas, offsetX, offsetY, 5, 16, gold);
    _drawPixel(canvas, offsetX, offsetY, 26, 16, gold);
    
    // 팔
    for (int y = 23; y <= 30; y++) {
      _drawPixel(canvas, offsetX, offsetY, 6, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 7, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, primary);
    }
  }

  // ========== 쇠 상체 아이템 ==========

  /// 철 탱크탑
  void _drawIronTankTop(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFE53935);
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    
    // 탱크탑 몸통
    for (int y = 19; y <= 32; y++) {
      for (int x = 10; x <= 21; x++) {
        Paint paint = primary;
        if (x <= 11 || x >= 20) paint = secondary;
        // 사이드 라인
        if (x == 10 || x == 21) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 어깨 부분 (피부 노출)
    for (int y = 19; y <= 20; y++) {
      _drawPixel(canvas, offsetX, offsetY, 9, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 22, y, skinPaint);
    }
    
    // 팔 (피부)
    for (int y = 19; y <= 30; y++) {
      _drawPixel(canvas, offsetX, offsetY, 6, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 7, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 8, y, y <= 21 ? skinShadow : primary);
      _drawPixel(canvas, offsetX, offsetY, 23, y, y <= 21 ? skinShadow : secondary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 25, y, skinPaint);
    }
    
    // 로고 (덤벨 아이콘)
    final logoPaint = Paint()..color = const Color(0xFF90A4AE);
    _drawPixel(canvas, offsetX, offsetY, 14, 24, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 15, 24, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 16, 24, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 17, 24, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 14, 23, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 14, 25, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 17, 23, logoPaint);
    _drawPixel(canvas, offsetX, offsetY, 17, 25, logoPaint);
  }

  /// 쇠사슬 갑옷
  void _drawChainMail(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final highlight = Paint()..color = data.accentColor ?? _lighten(data.primaryColor, 0.2);
    
    // 쇠사슬 패턴 몸통
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        // 체인 패턴 (체크 무늬)
        Paint paint;
        if ((x + y) % 2 == 0) {
          paint = primary;
        } else {
          paint = secondary;
        }
        // 하이라이트
        if (x >= 18 && y <= 23 && (x + y) % 3 == 0) {
          paint = highlight;
        }
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 목 부분 체인
    for (int x = 13; x <= 18; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 18, highlight);
    }
    
    // 팔
    for (int y = 19; y <= 30; y++) {
      final paint = (y % 2 == 0) ? primary : secondary;
      final paintAlt = (y % 2 == 0) ? secondary : primary;
      _drawPixel(canvas, offsetX, offsetY, 6, y, paint);
      _drawPixel(canvas, offsetX, offsetY, 7, y, paintAlt);
      _drawPixel(canvas, offsetX, offsetY, 24, y, paintAlt);
      _drawPixel(canvas, offsetX, offsetY, 25, y, paint);
    }
    
    // 허리 벨트
    final belt = Paint()..color = const Color(0xFF5D4037);
    for (int x = 9; x <= 22; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 30, belt);
    }
    // 버클
    _drawPixel(canvas, offsetX, offsetY, 15, 30, Paint()..color = const Color(0xFFFFD700));
    _drawPixel(canvas, offsetX, offsetY, 16, 30, Paint()..color = const Color(0xFFFFD700));
  }

  /// 강철 판금 갑옷
  void _drawPlateArmor(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.25);
    final highlight = Paint()..color = _lighten(data.primaryColor, 0.2);
    final gold = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    
    // 갑옷 본체
    for (int y = 19; y <= 32; y++) {
      for (int x = 8; x <= 23; x++) {
        Paint paint = primary;
        // 판금 라인
        if (y == 19 || y == 24 || y == 29 || y == 32) paint = secondary;
        if (x == 8 || x == 23) paint = secondary;
        // 하이라이트
        if (x >= 19 && x <= 21 && y >= 20 && y <= 23) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 금색 장식 라인
    for (int x = 9; x <= 22; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 22, gold);
      _drawPixel(canvas, offsetX, offsetY, x, 27, gold);
    }
    
    // 중앙 문양 (방패)
    _drawPixel(canvas, offsetX, offsetY, 15, 23, gold);
    _drawPixel(canvas, offsetX, offsetY, 16, 23, gold);
    _drawPixel(canvas, offsetX, offsetY, 14, 24, gold);
    _drawPixel(canvas, offsetX, offsetY, 15, 24, highlight);
    _drawPixel(canvas, offsetX, offsetY, 16, 24, highlight);
    _drawPixel(canvas, offsetX, offsetY, 17, 24, gold);
    _drawPixel(canvas, offsetX, offsetY, 15, 25, gold);
    _drawPixel(canvas, offsetX, offsetY, 16, 25, gold);
    
    // 대형 어깨 보호대
    for (int y = 16; y <= 22; y++) {
      _drawPixel(canvas, offsetX, offsetY, 3, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 4, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 5, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, highlight);
      _drawPixel(canvas, offsetX, offsetY, 7, y, secondary);
      
      _drawPixel(canvas, offsetX, offsetY, 24, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, highlight);
      _drawPixel(canvas, offsetX, offsetY, 26, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 27, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 28, y, secondary);
    }
    // 어깨 장식
    _drawPixel(canvas, offsetX, offsetY, 4, 15, gold);
    _drawPixel(canvas, offsetX, offsetY, 5, 15, gold);
    _drawPixel(canvas, offsetX, offsetY, 26, 15, gold);
    _drawPixel(canvas, offsetX, offsetY, 27, 15, gold);
    
    // 팔 갑옷
    for (int y = 23; y <= 30; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, highlight);
      _drawPixel(canvas, offsetX, offsetY, 7, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, highlight);
      _drawPixel(canvas, offsetX, offsetY, 26, y, primary);
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
      // 통나무 하체 아이템
      case SpriteType.woodShorts:
        _drawWoodShorts(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.forestPants:
        _drawForestPants(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.ancientGreaves:
        _drawAncientGreaves(canvas, offsetX, offsetY, spriteData);
        break;
      // 쇠 하체 아이템
      case SpriteType.ironGymShorts:
        _drawIronGymShorts(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.ironTrainingPants:
        _drawIronTrainingPants(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.warriorGreaves:
        _drawWarriorGreaves(canvas, offsetX, offsetY, spriteData);
        break;
      // 흙 하체 아이템
      case SpriteType.comfortPants:
        _drawComfortPants(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.meditationSkirt:
        _drawMeditationSkirt(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        _drawDefaultLegs(canvas, offsetX, offsetY);
    }
  }

  /// 기본 바지
  void _drawDefaultLegs(Canvas canvas, double offsetX, double offsetY) {
    final primary = Paint()..color = const Color(0xFF455A64);
    final shadow = Paint()..color = const Color(0xFF37474F);
    final shoePrimary = Paint()..color = const Color(0xFF5D4037);
    final shoeShadow = Paint()..color = const Color(0xFF3E2723);
    
    // 왼쪽 다리
    for (int y = 33; y <= 42; y++) {
      for (int x = 10; x <= 14; x++) {
        final paint = x <= 11 ? shadow : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 오른쪽 다리
    for (int y = 33; y <= 42; y++) {
      for (int x = 17; x <= 21; x++) {
        final paint = x >= 20 ? shadow : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 왼쪽 신발
    for (int y = 43; y <= 45; y++) {
      for (int x = 8; x <= 15; x++) {
        final paint = (y == 45 || x <= 9) ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 오른쪽 신발
    for (int y = 43; y <= 45; y++) {
      for (int x = 16; x <= 23; x++) {
        final paint = (y == 45 || x >= 22) ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
  }

  /// 나무 반바지
  void _drawWoodShorts(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    final shoePrimary = Paint()..color = const Color(0xFF8D6E63);
    final shoeShadow = Paint()..color = const Color(0xFF5D4037);
    
    // 반바지 (짧음)
    for (int y = 33; y <= 37; y++) {
      // 왼쪽
      for (int x = 10; x <= 14; x++) {
        final paint = (x + y) % 3 == 0 ? secondary : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽
      for (int x = 17; x <= 21; x++) {
        final paint = (x + y) % 3 == 0 ? secondary : primary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 다리 (피부 노출)
    for (int y = 38; y <= 42; y++) {
      _drawPixel(canvas, offsetX, offsetY, 11, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 12, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 13, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 18, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 19, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 20, y, skinPaint);
    }
    
    // 신발
    for (int y = 43; y <= 45; y++) {
      for (int x = 9; x <= 15; x++) {
        final paint = y == 45 ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 22; x++) {
        final paint = y == 45 ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
  }

  /// 숲의 바지
  void _drawForestPants(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = const Color(0xFF81C784);
    final shoePrimary = Paint()..color = const Color(0xFF4E342E);
    final shoeShadow = Paint()..color = const Color(0xFF3E2723);
    
    // 바지
    for (int y = 33; y <= 42; y++) {
      // 왼쪽 다리
      for (int x = 10; x <= 14; x++) {
        Paint paint = primary;
        if (x == 10) paint = secondary;
        if (x == 12 && y % 4 == 0) paint = accent; // 줄무늬
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽 다리
      for (int x = 17; x <= 21; x++) {
        Paint paint = primary;
        if (x == 21) paint = secondary;
        if (x == 19 && y % 4 == 0) paint = accent; // 줄무늬
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 포켓 디테일
    for (int x = 11; x <= 13; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 35, secondary);
    }
    for (int x = 18; x <= 20; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 35, secondary);
    }
    
    // 부츠
    for (int y = 43; y <= 45; y++) {
      for (int x = 8; x <= 15; x++) {
        final paint = (y == 45 || x <= 9) ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 23; x++) {
        final paint = (y == 45 || x >= 22) ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
  }

  /// 고대 나무 각반
  void _drawAncientGreaves(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.25);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    final shoePrimary = Paint()..color = const Color(0xFF3E2723);
    final shoeShadow = Paint()..color = const Color(0xFF1B0000);
    
    // 각반 (갑옷 바지)
    for (int y = 33; y <= 42; y++) {
      // 왼쪽 다리
      for (int x = 9; x <= 15; x++) {
        Paint paint = primary;
        if (x == 9 || x == 15) paint = secondary;
        if (y == 36 || y == 40) paint = secondary; // 판금 라인
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽 다리
      for (int x = 16; x <= 22; x++) {
        Paint paint = primary;
        if (x == 16 || x == 22) paint = secondary;
        if (y == 36 || y == 40) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 무릎 보호대
    for (int y = 37; y <= 39; y++) {
      _drawPixel(canvas, offsetX, offsetY, 12, y, accent);
      _drawPixel(canvas, offsetX, offsetY, 19, y, accent);
    }
    
    // 갑옷 부츠
    for (int y = 43; y <= 45; y++) {
      for (int x = 7; x <= 15; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (x == 7 || x == 15) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 24; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (x == 16 || x == 24) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 부츠 장식
    _drawPixel(canvas, offsetX, offsetY, 11, 43, accent);
    _drawPixel(canvas, offsetX, offsetY, 20, 43, accent);
  }

  // ========== 쇠 하체 아이템 ==========

  /// 철 운동 반바지
  void _drawIronGymShorts(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFE53935);
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    final shoePrimary = Paint()..color = const Color(0xFFE0E0E0);
    final shoeShadow = Paint()..color = const Color(0xFF9E9E9E);
    final shoeAccent = Paint()..color = const Color(0xFFE53935);
    
    // 운동 반바지
    for (int y = 33; y <= 38; y++) {
      // 왼쪽
      for (int x = 10; x <= 14; x++) {
        Paint paint = primary;
        if (x == 10) paint = accent; // 사이드 라인
        if (x == 14) paint = secondary; // 안쪽 그림자
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽
      for (int x = 17; x <= 21; x++) {
        Paint paint = primary;
        if (x == 21) paint = accent; // 사이드 라인
        if (x == 17) paint = secondary; // 안쪽 그림자
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 다리 (피부)
    for (int y = 39; y <= 42; y++) {
      _drawPixel(canvas, offsetX, offsetY, 11, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 12, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 13, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 18, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 19, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 20, y, skinPaint);
    }
    
    // 운동화
    for (int y = 43; y <= 45; y++) {
      for (int x = 9; x <= 15; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (x == 12 || x == 13) paint = shoeAccent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 22; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (x == 18 || x == 19) paint = shoeAccent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
  }

  /// 강철 트레이닝 바지
  void _drawIronTrainingPants(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF1E88E5);
    final shoePrimary = Paint()..color = const Color(0xFF212121);
    final shoeShadow = Paint()..color = const Color(0xFF000000);
    final shoeWhite = Paint()..color = Colors.white;
    
    // 트레이닝 바지
    for (int y = 33; y <= 42; y++) {
      // 왼쪽 다리
      for (int x = 10; x <= 14; x++) {
        Paint paint = primary;
        if (x == 10) paint = secondary;
        // 사이드 라인
        if (x == 11 && y >= 35) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽 다리
      for (int x = 17; x <= 21; x++) {
        Paint paint = primary;
        if (x == 21) paint = secondary;
        // 사이드 라인
        if (x == 20 && y >= 35) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 허리 밴드
    for (int x = 10; x <= 21; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 33, secondary);
    }
    
    // 무릎 부분 강조
    for (int x = 11; x <= 13; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 38, secondary);
    }
    for (int x = 18; x <= 20; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 38, secondary);
    }
    
    // 운동화
    for (int y = 43; y <= 45; y++) {
      for (int x = 8; x <= 15; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (y == 43 && x >= 10 && x <= 14) paint = shoeWhite;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 23; x++) {
        Paint paint = shoePrimary;
        if (y == 45) paint = shoeShadow;
        if (y == 43 && x >= 17 && x <= 21) paint = shoeWhite;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
  }

  /// 전사의 정강이 받침
  void _drawWarriorGreaves(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.25);
    final highlight = Paint()..color = _lighten(data.primaryColor, 0.15);
    final gold = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    final bootPrimary = Paint()..color = const Color(0xFF37474F);
    final bootShadow = Paint()..color = const Color(0xFF263238);
    
    // 갑옷 바지
    for (int y = 33; y <= 42; y++) {
      // 왼쪽 다리
      for (int x = 9; x <= 15; x++) {
        Paint paint = primary;
        if (x == 9 || x == 15) paint = secondary;
        // 판금 라인
        if (y == 35 || y == 39) paint = secondary;
        // 하이라이트
        if (x == 13 && y >= 36 && y <= 38) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽 다리
      for (int x = 16; x <= 22; x++) {
        Paint paint = primary;
        if (x == 16 || x == 22) paint = secondary;
        if (y == 35 || y == 39) paint = secondary;
        if (x == 18 && y >= 36 && y <= 38) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 무릎 보호대 (금색)
    for (int y = 36; y <= 38; y++) {
      _drawPixel(canvas, offsetX, offsetY, 11, y, gold);
      _drawPixel(canvas, offsetX, offsetY, 12, y, gold);
      _drawPixel(canvas, offsetX, offsetY, 19, y, gold);
      _drawPixel(canvas, offsetX, offsetY, 20, y, gold);
    }
    
    // 금속 부츠
    for (int y = 43; y <= 45; y++) {
      for (int x = 7; x <= 15; x++) {
        Paint paint = bootPrimary;
        if (y == 45) paint = bootShadow;
        if (x == 7 || x == 15) paint = secondary;
        // 금속 하이라이트
        if (y == 43 && x >= 10 && x <= 13) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 24; x++) {
        Paint paint = bootPrimary;
        if (y == 45) paint = bootShadow;
        if (x == 16 || x == 24) paint = secondary;
        if (y == 43 && x >= 18 && x <= 21) paint = highlight;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 부츠 장식
    _drawPixel(canvas, offsetX, offsetY, 11, 43, gold);
    _drawPixel(canvas, offsetX, offsetY, 20, 43, gold);
  }

  /// 머리 장식 그리기
  void _drawHead(Canvas canvas, double offsetX, double offsetY) {
    final itemId = sprite.headItemId;
    if (itemId == null) return;

    final spriteData = ItemSpriteRegistry.getSprite(itemId);
    if (spriteData == null) return;

    switch (spriteData.spriteType) {
      // 통나무 머리 아이템
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
      // 쇠 머리 아이템
      case SpriteType.ironHeadband:
        _drawIronHeadband(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.steelHelmet:
        _drawSteelHelmet(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.warriorHelm:
        _drawWarriorHelm(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.championCrown:
        _drawChampionCrown(canvas, offsetX, offsetY, spriteData);
        break;
      // 흙 머리 아이템
      case SpriteType.flowerCrown:
        _drawFlowerCrown(canvas, offsetX, offsetY, spriteData);
        break;
      case SpriteType.zenHeadband:
        _drawZenHeadband(canvas, offsetX, offsetY, spriteData);
        break;
      default:
        break;
    }
  }

  /// 나뭇잎 머리띠
  void _drawLeafBand(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final stem = Paint()..color = const Color(0xFF795548);
    
    // 머리띠 밴드
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, secondary);
      _drawPixel(canvas, offsetX, offsetY, x, 5, secondary);
    }
    
    // 나뭇잎 장식 (왼쪽)
    _drawPixel(canvas, offsetX, offsetY, 11, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 12, 2, primary);
    _drawPixel(canvas, offsetX, offsetY, 13, 1, primary);
    _drawPixel(canvas, offsetX, offsetY, 12, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 13, 2, primary);
    _drawPixel(canvas, offsetX, offsetY, 12, 4, stem);
    
    // 나뭇잎 장식 (오른쪽)
    _drawPixel(canvas, offsetX, offsetY, 20, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 19, 2, primary);
    _drawPixel(canvas, offsetX, offsetY, 18, 1, primary);
    _drawPixel(canvas, offsetX, offsetY, 19, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 18, 2, primary);
    _drawPixel(canvas, offsetX, offsetY, 19, 4, stem);
  }

  /// 나무 모자
  void _drawWoodHat(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final highlight = Paint()..color = _lighten(data.primaryColor, 0.15);
    
    // 모자 챙
    for (int x = 4; x <= 27; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, secondary);
      _drawPixel(canvas, offsetX, offsetY, x, 5, secondary);
    }
    
    // 모자 본체
    for (int y = 0; y <= 3; y++) {
      int startX = 9, endX = 22;
      if (y == 0) { startX = 11; endX = 20; }
      if (y == 1) { startX = 10; endX = 21; }
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        if (x >= 18 && y <= 2) paint = highlight;
        if (y == 3) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 밴드
    for (int x = 9; x <= 22; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 3, Paint()..color = const Color(0xFF5D4037));
    }
  }

  /// 통나무 왕관
  void _drawLogCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    final gem = Paint()..color = const Color(0xFF4FC3F7);
    
    // 왕관 베이스
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 3, primary);
      _drawPixel(canvas, offsetX, offsetY, x, 4, secondary);
    }
    
    // 왕관 뾰족한 부분 (5개)
    final spikes = [10, 13, 16, 19, 22];
    for (final sx in spikes) {
      _drawPixel(canvas, offsetX, offsetY, sx - 1, 2, primary);
      _drawPixel(canvas, offsetX, offsetY, sx, 2, primary);
      _drawPixel(canvas, offsetX, offsetY, sx, 1, secondary);
      _drawPixel(canvas, offsetX, offsetY, sx, 0, primary);
    }
    
    // 중앙 보석
    _drawPixel(canvas, offsetX, offsetY, 15, 1, gem);
    _drawPixel(canvas, offsetX, offsetY, 16, 1, gem);
    _drawPixel(canvas, offsetX, offsetY, 15, 2, accent);
    _drawPixel(canvas, offsetX, offsetY, 16, 2, accent);
    
    // 작은 보석들
    _drawPixel(canvas, offsetX, offsetY, 10, 2, gem);
    _drawPixel(canvas, offsetX, offsetY, 21, 2, gem);
  }

  /// 황금 통나무 왕관
  void _drawGoldenCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final shine = Paint()..color = _lighten(data.primaryColor, 0.3);
    final ruby = Paint()..color = const Color(0xFFE53935);
    final emerald = Paint()..color = const Color(0xFF43A047);
    final sapphire = Paint()..color = const Color(0xFF1E88E5);
    
    // 왕관 베이스 (더 넓게)
    for (int x = 6; x <= 25; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 3, primary);
      _drawPixel(canvas, offsetX, offsetY, x, 4, secondary);
    }
    
    // 왕관 뾰족한 부분 (7개, 더 화려하게)
    final spikes = [8, 11, 14, 16, 18, 21, 24];
    for (int i = 0; i < spikes.length; i++) {
      final sx = spikes[i];
      final height = i == 3 ? 4 : (i % 2 == 0 ? 3 : 2); // 중앙이 가장 높음
      
      for (int h = 0; h < height; h++) {
        _drawPixel(canvas, offsetX, offsetY, sx - 1, 2 - h, primary);
        _drawPixel(canvas, offsetX, offsetY, sx, 2 - h, h == 0 ? shine : primary);
        _drawPixel(canvas, offsetX, offsetY, sx + 1, 2 - h, secondary);
      }
    }
    
    // 중앙 큰 루비
    _drawPixel(canvas, offsetX, offsetY, 15, 0, ruby);
    _drawPixel(canvas, offsetX, offsetY, 16, 0, ruby);
    _drawPixel(canvas, offsetX, offsetY, 15, 1, ruby);
    _drawPixel(canvas, offsetX, offsetY, 16, 1, ruby);
    _drawPixel(canvas, offsetX, offsetY, 17, 0, Paint()..color = Colors.white.withValues(alpha: 0.5)); // 반짝임
    
    // 사이드 보석들
    _drawPixel(canvas, offsetX, offsetY, 10, 2, sapphire);
    _drawPixel(canvas, offsetX, offsetY, 11, 2, sapphire);
    _drawPixel(canvas, offsetX, offsetY, 20, 2, emerald);
    _drawPixel(canvas, offsetX, offsetY, 21, 2, emerald);
    
    // 하단 장식
    for (int x = 8; x <= 23; x += 3) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, shine);
    }
  }

  // ========== 쇠 머리 아이템 ==========

  /// 철 머리띠
  void _drawIronHeadband(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final highlight = Paint()..color = _lighten(data.primaryColor, 0.2);
    final shadow = Paint()..color = _darken(data.primaryColor, 0.15);
    
    // 메탈 밴드
    for (int x = 7; x <= 24; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, primary);
      // 메탈릭 하이라이트
      if (x >= 14 && x <= 18) {
        _drawPixel(canvas, offsetX, offsetY, x, 4, highlight);
      }
    }
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 5, shadow);
    }
    
    // 중앙 기어 장식
    _drawPixel(canvas, offsetX, offsetY, 15, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 16, 3, primary);
    _drawPixel(canvas, offsetX, offsetY, 14, 4, highlight);
    _drawPixel(canvas, offsetX, offsetY, 17, 4, highlight);
    
    // 사이드 볼트
    _drawPixel(canvas, offsetX, offsetY, 10, 4, highlight);
    _drawPixel(canvas, offsetX, offsetY, 21, 4, highlight);
  }

  /// 강철 헬멧
  void _drawSteelHelmet(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final highlight = Paint()..color = data.accentColor ?? _lighten(data.primaryColor, 0.25);
    
    // 헬멧 돔
    for (int y = 0; y <= 4; y++) {
      int startX = 10, endX = 21;
      if (y == 0) { startX = 13; endX = 18; }
      if (y == 1) { startX = 11; endX = 20; }
      if (y == 2) { startX = 10; endX = 21; }
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        // 하이라이트 (왼쪽 상단)
        if (x >= startX && x <= startX + 2 && y <= 2) paint = highlight;
        // 그림자 (오른쪽)
        if (x >= endX - 1) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 얼굴 가리개 (T자)
    for (int y = 5; y <= 8; y++) {
      _drawPixel(canvas, offsetX, offsetY, 15, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 16, y, secondary);
    }
    
    // 볼 가드
    for (int y = 6; y <= 10; y++) {
      _drawPixel(canvas, offsetX, offsetY, 8, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 9, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 22, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 23, y, primary);
    }
    
    // 리벳 장식
    _drawPixel(canvas, offsetX, offsetY, 12, 4, highlight);
    _drawPixel(canvas, offsetX, offsetY, 19, 4, highlight);
  }

  /// 전사의 투구
  void _drawWarriorHelm(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final feather = Paint()..color = data.accentColor ?? const Color(0xFFE53935);
    final gold = Paint()..color = const Color(0xFFFFD700);
    
    // 헬멧 본체
    for (int y = 1; y <= 5; y++) {
      int startX = 9, endX = 22;
      if (y == 1) { startX = 11; endX = 20; }
      if (y == 2) { startX = 10; endX = 21; }
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        if (x >= endX - 2) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 뿔/깃털 장식 (중앙)
    for (int y = -3; y <= 0; y++) {
      _drawPixel(canvas, offsetX, offsetY, 15, y, feather);
      _drawPixel(canvas, offsetX, offsetY, 16, y, feather);
    }
    _drawPixel(canvas, offsetX, offsetY, 14, -1, feather);
    _drawPixel(canvas, offsetX, offsetY, 17, -1, feather);
    _drawPixel(canvas, offsetX, offsetY, 14, 0, feather);
    _drawPixel(canvas, offsetX, offsetY, 17, 0, feather);
    
    // 페이스 가드
    for (int y = 6; y <= 12; y++) {
      if (y <= 8) {
        _drawPixel(canvas, offsetX, offsetY, 15, y, secondary);
        _drawPixel(canvas, offsetX, offsetY, 16, y, secondary);
      }
      // 사이드 가드
      _drawPixel(canvas, offsetX, offsetY, 7, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 8, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 23, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, primary);
    }
    
    // 금색 테두리
    for (int x = 10; x <= 21; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 5, gold);
    }
    
    // 볼트
    _drawPixel(canvas, offsetX, offsetY, 8, 7, gold);
    _drawPixel(canvas, offsetX, offsetY, 23, 7, gold);
  }

  /// 챔피언 왕관
  void _drawChampionCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final gold = Paint()..color = data.primaryColor;
    final steel = Paint()..color = data.secondaryColor ?? const Color(0xFF455A64);
    final shine = Paint()..color = _lighten(data.primaryColor, 0.3);
    final gem = Paint()..color = data.accentColor ?? const Color(0xFFE91E63);
    final diamond = Paint()..color = const Color(0xFF81D4FA);
    
    // 강철 베이스
    for (int x = 7; x <= 24; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, steel);
      _drawPixel(canvas, offsetX, offsetY, x, 5, steel);
    }
    
    // 금색 왕관
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 2, gold);
      _drawPixel(canvas, offsetX, offsetY, x, 3, gold);
    }
    
    // 왕관 뾰족 (5개, 다양한 높이)
    final spikes = [10, 13, 16, 19, 22];
    final heights = [2, 3, 4, 3, 2];
    for (int i = 0; i < spikes.length; i++) {
      final sx = spikes[i];
      for (int h = 0; h < heights[i]; h++) {
        _drawPixel(canvas, offsetX, offsetY, sx - 1, 1 - h, gold);
        _drawPixel(canvas, offsetX, offsetY, sx, 1 - h, shine);
        _drawPixel(canvas, offsetX, offsetY, sx + 1, 1 - h, gold);
      }
    }
    
    // 중앙 다이아몬드
    _drawPixel(canvas, offsetX, offsetY, 15, -2, diamond);
    _drawPixel(canvas, offsetX, offsetY, 16, -2, diamond);
    _drawPixel(canvas, offsetX, offsetY, 15, -1, diamond);
    _drawPixel(canvas, offsetX, offsetY, 16, -1, diamond);
    _drawPixel(canvas, offsetX, offsetY, 17, -2, Paint()..color = Colors.white.withValues(alpha: 0.7));
    
    // 사이드 보석
    _drawPixel(canvas, offsetX, offsetY, 10, 0, gem);
    _drawPixel(canvas, offsetX, offsetY, 22, 0, gem);
    _drawPixel(canvas, offsetX, offsetY, 10, 3, gem);
    _drawPixel(canvas, offsetX, offsetY, 22, 3, gem);
    
    // 트로피 느낌 날개 장식
    for (int y = 3; y <= 5; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, gold);
      _drawPixel(canvas, offsetX, offsetY, 6, y, shine);
      _drawPixel(canvas, offsetX, offsetY, 25, y, shine);
      _drawPixel(canvas, offsetX, offsetY, 26, y, gold);
    }
  }

  // ========== 흙 상체 아이템 ==========

  /// 자연의 로브
  void _drawNatureRobe(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF4CAF50);
    
    // 로브 몸통 (넓고 편안한 느낌)
    for (int y = 19; y <= 34; y++) {
      int startX = 7, endX = 24;
      // 아래로 갈수록 넓어짐
      if (y >= 30) { startX = 6; endX = 25; }
      if (y >= 33) { startX = 5; endX = 26; }
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        if (x <= startX + 1 || x >= endX - 1) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // V넥 칼라
    for (int y = 18; y <= 22; y++) {
      final offset = y - 18;
      _drawPixel(canvas, offsetX, offsetY, 14 - offset, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 17 + offset, y, secondary);
    }
    
    // 녹색 띠 (허리)
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 27, accent);
      _drawPixel(canvas, offsetX, offsetY, x, 28, accent);
    }
    // 띠 매듭
    _drawPixel(canvas, offsetX, offsetY, 15, 29, accent);
    _drawPixel(canvas, offsetX, offsetY, 16, 29, accent);
    _drawPixel(canvas, offsetX, offsetY, 14, 30, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 30, accent);
    
    // 소매 (넓음)
    for (int y = 19; y <= 28; y++) {
      _drawPixel(canvas, offsetX, offsetY, 5, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 6, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 25, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 26, y, primary);
    }
  }

  /// 대지의 판초
  void _drawEarthPoncho(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFF9800);
    final fringe = Paint()..color = _lighten(data.primaryColor, 0.1);
    
    // 판초 본체 (삼각형 느낌)
    for (int y = 17; y <= 35; y++) {
      // 위에서 아래로 넓어지는 형태
      int halfWidth = 4 + (y - 17) ~/ 2;
      int startX = 16 - halfWidth;
      int endX = 15 + halfWidth;
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        if (x <= startX + 1 || x >= endX - 1) paint = secondary;
        // 지그재그 패턴
        if ((x + y) % 4 == 0 && y >= 22) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 목 구멍
    for (int y = 17; y <= 19; y++) {
      for (int x = 14; x <= 17; x++) {
        // 목 구멍은 그리지 않음 (피부 보임)
      }
    }
    
    // 하단 술 장식
    for (int x = 4; x <= 27; x++) {
      if (x % 2 == 0) {
        _drawPixel(canvas, offsetX, offsetY, x, 36, fringe);
        _drawPixel(canvas, offsetX, offsetY, x, 37, fringe);
      }
    }
    
    // 기하학 문양 (중앙)
    for (int y = 24; y <= 28; y++) {
      _drawPixel(canvas, offsetX, offsetY, 15, y, accent);
      _drawPixel(canvas, offsetX, offsetY, 16, y, accent);
    }
    _drawPixel(canvas, offsetX, offsetY, 14, 26, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 26, accent);
  }

  // ========== 흙 하체 아이템 ==========

  /// 편안한 바지
  void _drawComfortPants(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.15);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFF4FC3F7);
    final shoePrimary = Paint()..color = const Color(0xFFBDBDBD);
    final shoeShadow = Paint()..color = const Color(0xFF9E9E9E);
    
    // 편안한 바지 (넓은 실루엣)
    for (int y = 33; y <= 42; y++) {
      // 왼쪽 다리 (넓음)
      for (int x = 9; x <= 15; x++) {
        Paint paint = primary;
        if (x == 9 || x == 15) paint = secondary;
        // 사이드 라인
        if (x == 10) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      // 오른쪽 다리
      for (int x = 16; x <= 22; x++) {
        Paint paint = primary;
        if (x == 16 || x == 22) paint = secondary;
        // 사이드 라인
        if (x == 21) paint = accent;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 허리 밴드 (신축성)
    for (int x = 9; x <= 22; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 33, secondary);
    }
    
    // 슬리퍼/샌들
    for (int y = 43; y <= 45; y++) {
      for (int x = 8; x <= 15; x++) {
        final paint = y == 45 ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
      for (int x = 16; x <= 23; x++) {
        final paint = y == 45 ? shoeShadow : shoePrimary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    // 샌들 끈
    _drawPixel(canvas, offsetX, offsetY, 11, 43, accent);
    _drawPixel(canvas, offsetX, offsetY, 12, 43, accent);
    _drawPixel(canvas, offsetX, offsetY, 19, 43, accent);
    _drawPixel(canvas, offsetX, offsetY, 20, 43, accent);
  }

  /// 명상 치마
  void _drawMeditationSkirt(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFD700);
    final skinPaint = Paint()..color = sprite.skinColor;
    final skinShadow = Paint()..color = _darken(sprite.skinColor, 0.15);
    
    // 치마 (넓게 퍼지는 형태)
    for (int y = 33; y <= 43; y++) {
      // 아래로 갈수록 넓어짐
      int halfWidth = 3 + (y - 33) ~/ 2;
      int startX = 16 - halfWidth;
      int endX = 15 + halfWidth;
      
      for (int x = startX; x <= endX; x++) {
        Paint paint = primary;
        if (x <= startX + 1 || x >= endX - 1) paint = secondary;
        // 주름 표현
        if ((x - startX) % 3 == 0) paint = secondary;
        _drawPixel(canvas, offsetX, offsetY, x, y, paint);
      }
    }
    
    // 금색 허리띠
    for (int x = 10; x <= 21; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 33, accent);
      _drawPixel(canvas, offsetX, offsetY, x, 34, accent);
    }
    
    // 하단 금색 테두리
    for (int x = 6; x <= 25; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 43, accent);
    }
    
    // 발 (맨발)
    for (int y = 44; y <= 45; y++) {
      _drawPixel(canvas, offsetX, offsetY, 10, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 11, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 12, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 19, y, skinShadow);
      _drawPixel(canvas, offsetX, offsetY, 20, y, skinPaint);
      _drawPixel(canvas, offsetX, offsetY, 21, y, skinPaint);
    }
  }

  // ========== 흙 머리 아이템 ==========

  /// 꽃 화관
  void _drawFlowerCrown(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final flower1 = Paint()..color = data.primaryColor; // 핑크
    final flower2 = Paint()..color = data.secondaryColor ?? const Color(0xFFFFEB3B); // 노랑
    final leaf = Paint()..color = data.accentColor ?? const Color(0xFF4CAF50);
    final center = Paint()..color = const Color(0xFFFFEB3B);
    
    // 화관 베이스 (녹색 줄기)
    for (int x = 8; x <= 23; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, leaf);
    }
    
    // 꽃들 (다양한 위치에)
    // 꽃 1 (왼쪽)
    _drawPixel(canvas, offsetX, offsetY, 9, 2, flower1);
    _drawPixel(canvas, offsetX, offsetY, 10, 1, flower1);
    _drawPixel(canvas, offsetX, offsetY, 11, 2, flower1);
    _drawPixel(canvas, offsetX, offsetY, 10, 3, flower1);
    _drawPixel(canvas, offsetX, offsetY, 10, 2, center);
    
    // 꽃 2 (중앙)
    _drawPixel(canvas, offsetX, offsetY, 14, 1, flower2);
    _drawPixel(canvas, offsetX, offsetY, 15, 0, flower2);
    _drawPixel(canvas, offsetX, offsetY, 16, 0, flower2);
    _drawPixel(canvas, offsetX, offsetY, 17, 1, flower2);
    _drawPixel(canvas, offsetX, offsetY, 15, 2, flower2);
    _drawPixel(canvas, offsetX, offsetY, 16, 2, flower2);
    _drawPixel(canvas, offsetX, offsetY, 15, 1, center);
    _drawPixel(canvas, offsetX, offsetY, 16, 1, center);
    
    // 꽃 3 (오른쪽)
    _drawPixel(canvas, offsetX, offsetY, 20, 2, flower1);
    _drawPixel(canvas, offsetX, offsetY, 21, 1, flower1);
    _drawPixel(canvas, offsetX, offsetY, 22, 2, flower1);
    _drawPixel(canvas, offsetX, offsetY, 21, 3, flower1);
    _drawPixel(canvas, offsetX, offsetY, 21, 2, center);
    
    // 작은 잎사귀들
    _drawPixel(canvas, offsetX, offsetY, 12, 3, leaf);
    _drawPixel(canvas, offsetX, offsetY, 13, 4, leaf);
    _drawPixel(canvas, offsetX, offsetY, 18, 4, leaf);
    _drawPixel(canvas, offsetX, offsetY, 19, 3, leaf);
  }

  /// 선(禪) 머리띠
  void _drawZenHeadband(Canvas canvas, double offsetX, double offsetY, ItemSpriteData data) {
    final primary = Paint()..color = data.primaryColor;
    final secondary = Paint()..color = data.secondaryColor ?? _darken(data.primaryColor, 0.2);
    final accent = Paint()..color = data.accentColor ?? const Color(0xFFFFEB3B);
    
    // 머리띠 본체
    for (int x = 7; x <= 24; x++) {
      _drawPixel(canvas, offsetX, offsetY, x, 4, primary);
      _drawPixel(canvas, offsetX, offsetY, x, 5, secondary);
    }
    
    // 중앙 원형 문양 (음양 느낌)
    _drawPixel(canvas, offsetX, offsetY, 14, 3, accent);
    _drawPixel(canvas, offsetX, offsetY, 15, 3, accent);
    _drawPixel(canvas, offsetX, offsetY, 16, 3, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 3, accent);
    _drawPixel(canvas, offsetX, offsetY, 14, 4, accent);
    _drawPixel(canvas, offsetX, offsetY, 17, 4, accent);
    _drawPixel(canvas, offsetX, offsetY, 15, 4, primary); // 음
    _drawPixel(canvas, offsetX, offsetY, 16, 4, secondary); // 양
    
    // 뒤로 늘어지는 띠
    for (int y = 6; y <= 10; y++) {
      _drawPixel(canvas, offsetX, offsetY, 7, y, primary);
      _drawPixel(canvas, offsetX, offsetY, 8, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 23, y, secondary);
      _drawPixel(canvas, offsetX, offsetY, 24, y, primary);
    }
    // 띠 끝 장식
    _drawPixel(canvas, offsetX, offsetY, 7, 11, accent);
    _drawPixel(canvas, offsetX, offsetY, 24, 11, accent);
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

  /// 색상 어둡게
  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// 색상 밝게
  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    return sprite != oldDelegate.sprite ||
        pixelSize != oldDelegate.pixelSize ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
