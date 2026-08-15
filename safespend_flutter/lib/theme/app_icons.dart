// ignore_for_file: non_constant_identifier_names
import 'package:flutter/cupertino.dart';
import 'package:iconify_flutter/icons/ph.dart';

/// Semantic icon aliases mapped to Phosphor Light icons.
/// All icons use the "light" weight for minimalist, clean, Core Line aesthetic.
class AppIcons {
  AppIcons._();

  // ── Navigation ──────────────────────────────────────────────────────────
  static const String home = Ph.house_bold;
  static const String aiCoach = Ph.sparkle_bold;
  static const String budgets = Ph.chart_pie_bold;
  static const String wealth = Ph.bank_bold;

  // ── Core Actions ────────────────────────────────────────────────────────
  static const String add = Ph.plus_bold;
  static const String edit = Ph.pencil_simple_light;
  static const String delete = Ph.trash_light;
  static const String close = Ph.x_light;
  static const String search = Ph.magnifying_glass_bold;
  static const String settings = Ph.gear_six_light;
  static const String back = Ph.arrow_left_bold;
  static const String more = Ph.dots_three_bold;
  static const String refresh = Ph.arrows_clockwise_bold;
  static const String undo = Ph.arrow_counter_clockwise_bold;
  static const String filter = Ph.funnel_bold;

  /// Sort order — bars shrinking/growing beside a direction arrow, which reads
  /// as "biggest first" / "smallest first" rather than a market trend.
  static const String sortDescending = Ph.sort_descending_bold;
  static const String sortAscending = Ph.sort_ascending_bold;
  static const String sliders = Ph.sliders_horizontal_bold;
  static const String zoomIn = Ph.magnifying_glass_plus_bold;
  static const String archive = Ph.archive_bold;
  static const String list = Ph.list_bold;
  static const String flag = Ph.flag_bold;

  // ── Chevrons & Carets ────────────────────────────────────────────────────
  static const String caretRight = Ph.caret_right_bold;
  static const String caretDown = Ph.caret_down_bold;
  static const String caretLeft = Ph.caret_left_bold;
  static const String caretUpDown = Ph.arrows_down_up_bold;
  static const String arrowRight = Ph.arrow_right_bold;

  // ── Status & Feedback ────────────────────────────────────────────────────
  static const String checkCircle = Ph.check_circle_bold;
  static const String check = Ph.check_bold;
  static const String info = Ph.info_bold;
  static const String warning = Ph.warning_circle_bold;
  static const String circleEmpty = Ph.circle_bold;

  // ── Financial ────────────────────────────────────────────────────────────
  static const String wallet = Ph.wallet_light;
  static const String bank = Ph.bank_light;
  static const String savings = Ph.coins_light;
  static const String trendUp = Ph.trend_up_light;
  static const String trendDown = Ph.trend_down_bold;

  /// Investments / portfolio — a market line chart, not a generic trend arrow.
  static const String investments = Ph.chart_line_up_bold;
  static const String creditCard = Ph.credit_card_light;
  static const String dollar = Ph.currency_dollar_bold;
  static const String money = Ph.money_light;
  static const String receipt = Ph.receipt_bold;
  static const String sell = Ph.tag_bold;
  static const String chartLine = Ph.chart_line_bold;
  static const String chartBar = Ph.chart_bar_bold;
  static const String chartPie = Ph.chart_pie_bold;
  static const String candlestick = Ph.chart_line_bold; // closest match
  static const String percent = Ph.percent_bold;
  static const String coins = Ph.coins_bold;
  static const String piggyBank = Ph.coins_bold; // closest match
  static const String handCoins = Ph.money_bold; // closest match

  // ── Transaction Types ────────────────────────────────────────────────────
  static const String expense = Ph.arrow_up_bold;
  static const String income = Ph.arrow_down_bold;
  static const String transfer = Ph.arrows_left_right_bold;
  static const String payment = Ph.money_bold;
  static const String withdrawal = Ph.wallet_bold;

  // ── Subscriptions / Recurring ────────────────────────────────────────────
  static const String repeat = Ph.repeat_bold;
  static const String autoRenew = Ph.arrows_clockwise_light;
  static const String calendar = Ph.calendar_bold;
  static const String clock = Ph.clock_bold;

  // ── Categories ───────────────────────────────────────────────────────────
  static const String categoryIcon = Ph.squares_four_light;
  static const String tag = Ph.tag_bold;
  static const String lightning = Ph.lightning_light;
  static const String phone = Ph.device_mobile_light;
  static const String tv = Ph.television_simple_light;
  static const String shield = Ph.shield_light;
  static const String cart = Ph.shopping_cart_light;
  static const String car = Ph.car_light;
  static const String food = Ph.fork_knife_light;
  static const String shoppingBag = Ph.shopping_bag_light;
  static const String heart = Ph.heart_light;
  static const String gaming = Ph.game_controller_light;
  static const String personal = Ph.user_circle_light;
  static const String education = Ph.graduation_cap_light;
  static const String travel = Ph.airplane_light;
  static const String gift = Ph.gift_light;
  static const String pets = Ph.paw_print_light;
  static const String gym = Ph.barbell_light;
  static const String coffee = Ph.coffee_light;
  static const String baby = Ph.baby_light;
  static const String tools = Ph.wrench_light;
  static const String notes = Ph.note_pencil_bold;

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String email = Ph.envelope_bold;
  static const String lock = Ph.lock_key_bold;
  static const String eyeOn = Ph.eye_bold;
  static const String eyeOff = Ph.eye_slash_bold;

  // ── User & Social ────────────────────────────────────────────────────────
  static const String user = Ph.user_bold;
  static const String userCircle = Ph.user_circle_bold;
  static const String users = Ph.users_bold;
  static const String person = Ph.person_bold;
  static const String chat = Ph.chat_circle_bold;
  static const String folder = Ph.folder_bold;

  // ── Media ────────────────────────────────────────────────────────────────
  static const String image = Ph.image_bold;
  static const String camera = Ph.camera_bold;
  static const String pdf = Ph.file_pdf_bold;
  static const String minus = Ph.minus_bold;
  static const String text = Ph.text_t_bold;
  static const String hash = Ph.hash_bold;

  // ── Settings ─────────────────────────────────────────────────────────────
  static const String lightMode = Ph.sun_bold;
  static const String darkMode = Ph.moon_bold;
  static const String bell = Ph.bell_bold;
  static const String help = Ph.question_bold;
  static const String logout = Ph.sign_out_bold;
  static const String smartphone = Ph.device_mobile_bold;

  // ── Onboarding ───────────────────────────────────────────────────────────
  static const String bolt = Ph.lightning_bold;
  static const String brain = Ph.sparkle_bold;
  static const String eye = Ph.eye_bold;
  static const String today = Ph.calendar_bold;
  static const String swap = Ph.arrows_left_right_bold;
}

/// Renders the app's semantic icon aliases using Cupertino/SF Symbols.
class AppIcon extends StatelessWidget {
  final String icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      _resolve(icon),
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  static IconData _resolve(String icon) {
    if (icon == AppIcons.home) return CupertinoIcons.house;
    if (icon == AppIcons.aiCoach) return CupertinoIcons.sparkles;
    if (icon == AppIcons.budgets) return CupertinoIcons.chart_pie;
    if (icon == AppIcons.wealth) return CupertinoIcons.building_2_fill;
    if (icon == AppIcons.add) return CupertinoIcons.add;
    if (icon == AppIcons.edit) return CupertinoIcons.square_pencil;
    if (icon == AppIcons.delete) return CupertinoIcons.trash;
    if (icon == AppIcons.close) return CupertinoIcons.xmark;
    if (icon == AppIcons.search) return CupertinoIcons.search;
    if (icon == AppIcons.settings) return CupertinoIcons.gear;
    if (icon == AppIcons.back) return CupertinoIcons.chevron_back;
    if (icon == AppIcons.more) return CupertinoIcons.ellipsis;
    if (icon == AppIcons.refresh) return CupertinoIcons.arrow_clockwise;
    if (icon == AppIcons.undo) return CupertinoIcons.arrow_uturn_left;
    if (icon == AppIcons.filter) {
      return CupertinoIcons.line_horizontal_3_decrease;
    }
    if (icon == AppIcons.sliders) return CupertinoIcons.slider_horizontal_3;
    if (icon == AppIcons.zoomIn) return CupertinoIcons.search_circle;
    if (icon == AppIcons.archive) return CupertinoIcons.archivebox;
    if (icon == AppIcons.list) return CupertinoIcons.list_bullet;
    if (icon == AppIcons.flag) return CupertinoIcons.flag;
    if (icon == AppIcons.caretRight) return CupertinoIcons.chevron_forward;
    if (icon == AppIcons.caretDown) return CupertinoIcons.chevron_down;
    if (icon == AppIcons.caretLeft) return CupertinoIcons.chevron_back;
    if (icon == AppIcons.caretUpDown) {
      return CupertinoIcons.chevron_up_chevron_down;
    }
    if (icon == AppIcons.arrowRight) return CupertinoIcons.arrow_right;
    if (icon == AppIcons.checkCircle) return CupertinoIcons.checkmark_circle;
    if (icon == AppIcons.check) return CupertinoIcons.checkmark;
    if (icon == AppIcons.info) return CupertinoIcons.info_circle;
    if (icon == AppIcons.warning) {
      return CupertinoIcons.exclamationmark_triangle;
    }
    if (icon == AppIcons.circleEmpty) return CupertinoIcons.circle;
    if (icon == AppIcons.wallet) return CupertinoIcons.creditcard;
    if (icon == AppIcons.bank) return CupertinoIcons.building_2_fill;
    if (icon == AppIcons.savings) return CupertinoIcons.money_dollar_circle;
    if (icon == AppIcons.trendUp) return CupertinoIcons.chart_bar_fill;
    if (icon == AppIcons.trendDown) return CupertinoIcons.chart_bar;
    if (icon == AppIcons.investments) return CupertinoIcons.graph_square;
    if (icon == AppIcons.sortDescending) return CupertinoIcons.sort_down;
    if (icon == AppIcons.sortAscending) return CupertinoIcons.sort_up;
    if (icon == AppIcons.creditCard) return CupertinoIcons.creditcard;
    if (icon == AppIcons.dollar) return CupertinoIcons.money_dollar;
    if (icon == AppIcons.money) return CupertinoIcons.money_dollar_circle;
    if (icon == AppIcons.receipt) return CupertinoIcons.doc_text;
    if (icon == AppIcons.sell) return CupertinoIcons.tag;
    if (icon == AppIcons.chartLine) return CupertinoIcons.chart_bar;
    if (icon == AppIcons.chartBar) return CupertinoIcons.chart_bar;
    if (icon == AppIcons.chartPie) return CupertinoIcons.chart_pie;
    if (icon == AppIcons.candlestick) return CupertinoIcons.chart_bar_square;
    if (icon == AppIcons.percent) return CupertinoIcons.percent;
    if (icon == AppIcons.coins) return CupertinoIcons.money_dollar_circle_fill;
    if (icon == AppIcons.piggyBank) {
      return CupertinoIcons.money_dollar_circle_fill;
    }
    if (icon == AppIcons.handCoins) return CupertinoIcons.money_dollar_circle;
    if (icon == AppIcons.expense) return CupertinoIcons.arrow_up;
    if (icon == AppIcons.income) return CupertinoIcons.arrow_down;
    if (icon == AppIcons.transfer) return CupertinoIcons.arrow_right_arrow_left;
    if (icon == AppIcons.payment) return CupertinoIcons.money_dollar_circle;
    if (icon == AppIcons.withdrawal) return CupertinoIcons.creditcard_fill;
    if (icon == AppIcons.repeat) return CupertinoIcons.repeat;
    if (icon == AppIcons.autoRenew) return CupertinoIcons.arrow_2_circlepath;
    if (icon == AppIcons.calendar) return CupertinoIcons.calendar;
    if (icon == AppIcons.clock) return CupertinoIcons.clock;
    if (icon == AppIcons.categoryIcon) return CupertinoIcons.square_grid_2x2;
    if (icon == AppIcons.tag) return CupertinoIcons.tag;
    if (icon == AppIcons.lightning) return CupertinoIcons.bolt;
    if (icon == AppIcons.phone) return CupertinoIcons.device_phone_portrait;
    if (icon == AppIcons.tv) return CupertinoIcons.tv;
    if (icon == AppIcons.shield) return CupertinoIcons.shield;
    if (icon == AppIcons.cart) return CupertinoIcons.cart;
    if (icon == AppIcons.car) return CupertinoIcons.car_detailed;
    if (icon == AppIcons.food) return CupertinoIcons.cart;
    if (icon == AppIcons.shoppingBag) return CupertinoIcons.bag;
    if (icon == AppIcons.heart) return CupertinoIcons.heart;
    if (icon == AppIcons.gaming) return CupertinoIcons.gamecontroller;
    if (icon == AppIcons.personal) return CupertinoIcons.person_circle;
    if (icon == AppIcons.education) return CupertinoIcons.book;
    if (icon == AppIcons.travel) return CupertinoIcons.airplane;
    if (icon == AppIcons.gift) return CupertinoIcons.gift;
    if (icon == AppIcons.pets) return CupertinoIcons.paw;
    if (icon == AppIcons.gym) return CupertinoIcons.sportscourt;
    if (icon == AppIcons.coffee) return CupertinoIcons.drop;
    if (icon == AppIcons.baby) return CupertinoIcons.person_2;
    if (icon == AppIcons.tools) return CupertinoIcons.wrench;
    if (icon == AppIcons.notes) return CupertinoIcons.doc_text;
    if (icon == AppIcons.email) return CupertinoIcons.envelope;
    if (icon == AppIcons.lock) return CupertinoIcons.lock;
    if (icon == AppIcons.eyeOn) return CupertinoIcons.eye;
    if (icon == AppIcons.eyeOff) return CupertinoIcons.eye_slash;
    if (icon == AppIcons.user) return CupertinoIcons.person;
    if (icon == AppIcons.userCircle) return CupertinoIcons.person_circle;
    if (icon == AppIcons.users) return CupertinoIcons.person_2;
    if (icon == AppIcons.person) return CupertinoIcons.person_fill;
    if (icon == AppIcons.chat) return CupertinoIcons.chat_bubble;
    if (icon == AppIcons.folder) return CupertinoIcons.folder;
    if (icon == AppIcons.image) return CupertinoIcons.photo;
    if (icon == AppIcons.camera) return CupertinoIcons.camera;
    if (icon == AppIcons.pdf) return CupertinoIcons.doc_fill;
    if (icon == AppIcons.minus) return CupertinoIcons.minus;
    if (icon == AppIcons.text) return CupertinoIcons.textformat;
    if (icon == AppIcons.hash) return CupertinoIcons.number;
    if (icon == AppIcons.lightMode) return CupertinoIcons.sun_max;
    if (icon == AppIcons.darkMode) return CupertinoIcons.moon;
    if (icon == AppIcons.bell) return CupertinoIcons.bell;
    if (icon == AppIcons.help) return CupertinoIcons.question_circle;
    if (icon == AppIcons.logout) return CupertinoIcons.square_arrow_right;
    if (icon == AppIcons.smartphone) {
      return CupertinoIcons.device_phone_portrait;
    }
    if (icon == AppIcons.bolt) return CupertinoIcons.bolt_fill;
    if (icon == AppIcons.brain) return CupertinoIcons.sparkles;
    if (icon == AppIcons.eye) return CupertinoIcons.eye;
    if (icon == AppIcons.today) return CupertinoIcons.calendar_today;
    if (icon == AppIcons.swap) return CupertinoIcons.arrow_right_arrow_left;
    return CupertinoIcons.circle;
  }
}
