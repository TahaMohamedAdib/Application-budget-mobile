// ignore_for_file: non_constant_identifier_names
import 'package:iconify_flutter/icons/ph.dart';

/// Semantic icon aliases mapped to Phosphor Light icons.
/// All icons use the "light" weight for minimalist, clean, Core Line aesthetic.
class AppIcons {
  AppIcons._();

  // ── Navigation ──────────────────────────────────────────────────────────
  static const String home           = Ph.house_light;
  static const String aiCoach        = Ph.sparkle_bold;
  static const String budgets        = Ph.chart_pie_bold;
  static const String wealth         = Ph.bank_bold;

  // ── Core Actions ────────────────────────────────────────────────────────
  static const String add            = Ph.plus_light;
  static const String edit           = Ph.pencil_simple_light;
  static const String delete         = Ph.trash_light;
  static const String close          = Ph.x_light;
  static const String search         = Ph.magnifying_glass_bold;
  static const String settings       = Ph.gear_six_light;
  static const String back           = Ph.arrow_left_bold;
  static const String more           = Ph.dots_three_bold;
  static const String refresh        = Ph.arrows_clockwise_bold;
  static const String undo           = Ph.arrow_counter_clockwise_bold;
  static const String filter         = Ph.funnel_bold;
  static const String sliders        = Ph.sliders_horizontal_bold;
  static const String zoomIn         = Ph.magnifying_glass_plus_bold;
  static const String archive        = Ph.archive_bold;
  static const String list           = Ph.list_bold;
  static const String flag           = Ph.flag_bold;

  // ── Chevrons & Carets ────────────────────────────────────────────────────
  static const String caretRight     = Ph.caret_right_bold;
  static const String caretDown      = Ph.caret_down_bold;
  static const String caretLeft      = Ph.caret_left_bold;
  static const String caretUpDown    = Ph.arrows_down_up_bold;
  static const String arrowRight     = Ph.arrow_right_bold;

  // ── Status & Feedback ────────────────────────────────────────────────────
  static const String checkCircle    = Ph.check_circle_bold;
  static const String check          = Ph.check_bold;
  static const String info           = Ph.info_bold;
  static const String warning        = Ph.warning_circle_bold;
  static const String circleEmpty    = Ph.circle_bold;

  // ── Financial ────────────────────────────────────────────────────────────
  static const String wallet         = Ph.wallet_light;
  static const String bank           = Ph.bank_light;
  static const String savings        = Ph.coins_light;
  static const String trendUp        = Ph.trend_up_light;
  static const String trendDown      = Ph.trend_down_bold;
  static const String creditCard     = Ph.credit_card_light;
  static const String dollar         = Ph.currency_dollar_bold;
  static const String money          = Ph.money_light;
  static const String receipt        = Ph.receipt_bold;
  static const String sell           = Ph.tag_bold;
  static const String chartLine      = Ph.chart_line_bold;
  static const String chartBar       = Ph.chart_bar_bold;
  static const String chartPie       = Ph.chart_pie_bold;
  static const String candlestick    = Ph.chart_line_bold; // closest match
  static const String percent        = Ph.percent_bold;
  static const String coins          = Ph.coins_bold;
  static const String piggyBank      = Ph.coins_bold;     // closest match
  static const String handCoins      = Ph.money_bold;     // closest match

  // ── Transaction Types ────────────────────────────────────────────────────
  static const String expense        = Ph.arrow_up_bold;
  static const String income         = Ph.arrow_down_bold;
  static const String transfer       = Ph.arrows_left_right_bold;
  static const String payment        = Ph.money_bold;
  static const String withdrawal     = Ph.wallet_bold;

  // ── Subscriptions / Recurring ────────────────────────────────────────────
  static const String repeat         = Ph.repeat_bold;
  static const String autoRenew      = Ph.arrows_clockwise_light;
  static const String calendar       = Ph.calendar_bold;
  static const String clock          = Ph.clock_bold;

  // ── Categories ───────────────────────────────────────────────────────────
  static const String categoryIcon   = Ph.squares_four_light;
  static const String tag            = Ph.tag_bold;
  static const String lightning      = Ph.lightning_light;
  static const String phone          = Ph.device_mobile_light;
  static const String tv             = Ph.television_simple_light;
  static const String shield         = Ph.shield_light;
  static const String cart           = Ph.shopping_cart_light;
  static const String car            = Ph.car_light;
  static const String food           = Ph.fork_knife_light;
  static const String shoppingBag    = Ph.shopping_bag_light;
  static const String heart          = Ph.heart_light;
  static const String gaming         = Ph.game_controller_light;
  static const String personal       = Ph.user_circle_light;
  static const String education      = Ph.graduation_cap_light;
  static const String travel         = Ph.airplane_light;
  static const String gift           = Ph.gift_light;
  static const String pets           = Ph.paw_print_light;
  static const String gym            = Ph.barbell_light;
  static const String coffee         = Ph.coffee_light;
  static const String baby           = Ph.baby_light;
  static const String tools          = Ph.wrench_light;
  static const String notes          = Ph.note_pencil_bold;

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String email          = Ph.envelope_bold;
  static const String lock           = Ph.lock_key_bold;
  static const String eyeOn          = Ph.eye_bold;
  static const String eyeOff         = Ph.eye_slash_bold;

  // ── User & Social ────────────────────────────────────────────────────────
  static const String user           = Ph.user_bold;
  static const String userCircle     = Ph.user_circle_bold;
  static const String users          = Ph.users_bold;
  static const String person         = Ph.person_bold;
  static const String chat           = Ph.chat_circle_bold;
  static const String folder         = Ph.folder_bold;

  // ── Media ────────────────────────────────────────────────────────────────
  static const String image          = Ph.image_bold;
  static const String camera         = Ph.camera_bold;
  static const String pdf            = Ph.file_pdf_bold;
  static const String minus          = Ph.minus_bold;
  static const String text           = Ph.text_t_bold;
  static const String hash           = Ph.hash_bold;

  // ── Settings ─────────────────────────────────────────────────────────────
  static const String lightMode      = Ph.sun_bold;
  static const String darkMode       = Ph.moon_bold;
  static const String bell           = Ph.bell_bold;
  static const String help           = Ph.question_bold;
  static const String logout         = Ph.sign_out_bold;
  static const String smartphone     = Ph.device_mobile_bold;

  // ── Onboarding ───────────────────────────────────────────────────────────
  static const String bolt           = Ph.lightning_bold;
  static const String brain          = Ph.sparkle_bold;
  static const String eye            = Ph.eye_bold;
  static const String today          = Ph.calendar_bold;
  static const String swap           = Ph.arrows_left_right_bold;
}
