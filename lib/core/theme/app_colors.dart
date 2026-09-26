import 'package:flutter/material.dart';

/// SMART-GO Design System — Canonical Color Tokens
///
/// Palette foundation:
///   Deep Navy    #0F2027   — brand anchor / dark-mode base
///   Ocean Teal   #087E8B   — primary interactive
///   Smart Cyan   #12A8B5   — primary light variant
///   Emerald Live #16A085   — success / live status
///   Warm Sand    #F4E7D0   — light accent / highlight
///   Coral        #FF6B5E   — danger / error
///   Amber        #F2B84B   — warning
abstract final class AppColors {
  // ── Brand Core ──────────────────────────────────────────────────────────────
  static const deepNavy = Color(0xFF0F2027);
  static const oceanTeal = Color(0xFF087E8B);
  static const smartCyan = Color(0xFF12A8B5);
  static const emeraldLive = Color(0xFF16A085);
  static const warmSand = Color(0xFFF4E7D0);
  static const coral = Color(0xFFFF6B5E);
  static const amber = Color(0xFFF2B84B);

  // ── Semantic — Light Mode ───────────────────────────────────────────────────
  static const primary = oceanTeal;
  static const primaryLight = smartCyan;
  static const primaryContainer = Color(0xFFD4F2F5);   // very light teal wash
  static const accent = coral;
  static const success = emeraldLive;
  static const warning = amber;
  static const danger = Color(0xFFE53935);
  static const inactive = Color(0xFF8A8F98);

  // Light surfaces
  static const background = Color(0xFFF4F8F9);          // very faint teal-grey
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF6F7);      // teal-tinted grey card
  static const outline = Color(0xFFDBE6E8);
  static const outlineVariant = Color(0xFFCCD9DC);

  // Light text
  static const textPrimary = Color(0xFF16292D);         // near-black navy
  static const textSecondary = Color(0xFF4F6770);       // mid teal-grey

  // ── Semantic — Dark Mode ────────────────────────────────────────────────────
  // Background levels (3-level elevation system)
  static const darkBg = Color(0xFF081419);              // deepest — Scaffold bg
  static const darkSurface = Color(0xFF10242A);         // L1 — cards, bottom sheets
  static const darkSurfaceElevated = Color(0xFF163038); // L2 — modals, overlays

  static const darkPrimary = Color(0xFF17C0CF);         // brightened teal for dark bg
  static const darkPrimaryContainer = Color(0xFF0C3E46);
  static const darkAccent = Color(0xFFFF8C83);          // slightly lighter coral
  static const darkSuccess = Color(0xFF1FBE97);
  static const darkWarning = Color(0xFFF8CC6E);
  static const darkDanger = Color(0xFFFF6B6B);

  static const darkOutline = Color(0xFF1E3A42);
  static const darkOutlineVariant = Color(0xFF2A4D58);

  static const darkTextPrimary = Color(0xFFE4F0F2);     // almost-white with teal tint
  static const darkTextSecondary = Color(0xFF7BAAB5);   // muted teal-grey
}
