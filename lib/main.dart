
import 'services/supabase_service.dart';
import 'services/account_service.dart';
import 'profile/business_profile_page.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';
import 'services/supabase_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('th_TH', null);
    await initializeDateFormatting('en_US', null);

    await SupabaseService.initialize();

    runApp(const SkyBusinessApp());
  } catch (e, stackTrace) {
    debugPrint('SKY BUSINESS STARTUP ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF070B14),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 55,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SKY BUSINESS STARTUP ERROR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SelectableText(
                    e.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SKY BUSINESS — BUSINESS COMMAND CENTER
// ============================================================

const navy = Color(0xFF070B14);
const panel = Color(0xFF101827);
const panel2 = Color(0xFF172337);
const cyan = Color(0xFF36D9FF);
const blue = Color(0xFF637BFF);
const green = Color(0xFF42D6A0);
const red = Color(0xFFFF718B);
const orange = Color(0xFFFFB454);
const purple = Color(0xFFB18CFF);

String money(num v) => NumberFormat.currency(
  locale: 'th_TH',
  symbol: '฿',
  decimalDigits: 2,
).format(v);

String dateText(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String compact(num v) {
  if (v.abs() >= 1000000000) {
    return '฿${(v / 1000000000).toStringAsFixed(2)}B';
  }
  if (v.abs() >= 1000000) {
    return '฿${(v / 1000000).toStringAsFixed(2)}M';
  }
  if (v.abs() >= 100000) {
    return '฿${(v / 1000).toStringAsFixed(1)}K';
  }
  return money(v);
}

const modules = <BusinessModule>[
  BusinessModule('finance', 'การเงิน', 'Financial Management',
      Icons.account_balance_wallet_rounded, cyan,
      'หมวดหมู่ / รายละเอียด', amount: true,
      statuses: ['รายรับ', 'รายจ่าย']),
  BusinessModule('budget', 'งบประมาณ', 'Budget Management',
      Icons.pie_chart_rounded, purple,
      'หมวดหมู่ / รายละเอียด', amount: true,
      statuses: ['ใช้งาน', 'ใกล้เต็ม', 'ปิดงบ']),
  BusinessModule('invoices', 'ใบแจ้งหนี้', 'Invoice & Billing',
      Icons.receipt_long_rounded, orange,
      'รายละเอียดใบแจ้งหนี้', amount: true,
      statuses: ['ร่าง', 'ส่งแล้ว', 'ชำระแล้ว', 'เกินกำหนด']),
  BusinessModule('customers', 'ลูกค้า', 'Customer CRM',
      Icons.groups_rounded, green, 'เบอร์โทร / อีเมล / หมายเหตุ'),
  BusinessModule('suppliers', 'ผู้จำหน่าย', 'Supplier Management',
      Icons.local_shipping_rounded, blue, 'ช่องทางติดต่อ / รายละเอียด'),
  BusinessModule('inventory', 'คลังสินค้า', 'Inventory Management',
      Icons.inventory_2_rounded, orange,
      'SKU / จำนวน / หน่วย', amount: true,
      statuses: ['มีสินค้า', 'สินค้าใกล้หมด', 'หมดสต็อก']),
  BusinessModule('sales', 'ยอดขาย', 'Sales & Orders',
      Icons.point_of_sale_rounded, green,
      'ลูกค้า / สินค้า / รายละเอียด', amount: true,
      statuses: ['รับคำสั่งซื้อ', 'กำลังจัดส่ง', 'สำเร็จ', 'ยกเลิก']),
  BusinessModule('employees', 'พนักงาน', 'Employee Management',
      Icons.badge_rounded, cyan, 'ตำแหน่ง / เบอร์โทร / หมายเหตุ'),
  BusinessModule('payroll', 'เงินเดือน', 'Payroll Management',
      Icons.payments_rounded, green, 'รอบเงินเดือน / รายละเอียด',
      amount: true, statuses: ['รอจ่าย', 'จ่ายแล้ว']),
  BusinessModule('projects', 'โครงการ', 'Project Management',
      Icons.work_rounded, purple, 'ผู้รับผิดชอบ / รายละเอียด',
      amount: true,
      statuses: ['วางแผน', 'กำลังดำเนินการ', 'เสร็จสิ้น', 'พักโครงการ']),
  BusinessModule('tasks', 'งานและทีม', 'Task Management',
      Icons.task_alt_rounded, cyan, 'ผู้รับผิดชอบ / รายละเอียด',
      statuses: ['รอดำเนินการ', 'กำลังทำ', 'เสร็จสิ้น', 'ยกเลิก']),
  BusinessModule('calendar', 'ปฏิทิน', 'Business Calendar',
      Icons.calendar_month_rounded, blue, 'สถานที่ / ผู้เกี่ยวข้อง'),
  BusinessModule('assets', 'ทรัพย์สิน', 'Asset Management',
      Icons.devices_rounded, orange, 'รหัส / สถานที่ / หมายเหตุ',
      amount: true,
      statuses: ['ใช้งาน', 'ซ่อมบำรุง', 'จำหน่ายแล้ว']),
  BusinessModule('loans', 'หนี้สิน', 'Loan & Installment',
      Icons.credit_score_rounded, red, 'เจ้าหนี้ / รายละเอียด',
      amount: true,
      statuses: ['กำลังผ่อน', 'ชำระครบ', 'พักชำระ']),
  BusinessModule('reports', 'รายงาน', 'Analytics & Reports',
      Icons.analytics_rounded, purple, ''),
  BusinessModule('settings', 'ตั้งค่า', 'System & Backup',
      Icons.settings_rounded, Colors.white70, ''),
];

class BusinessModule {
  final String id;
  final String name;
  final String english;
  final IconData icon;
  final Color color;
  final String detailLabel;
  final bool amount;
  final List<String> statuses;

  const BusinessModule(
    this.id,
    this.name,
    this.english,
    this.icon,
    this.color,
    this.detailLabel, {
    this.amount = false,
    this.statuses = const ['รอดำเนินการ', 'กำลังดำเนินการ', 'เสร็จสิ้น'],
  });
}

// ============================================================
// BUSINESS RECORD
// ============================================================

class BusinessRecord {
  final String id;
  final String moduleId;
  String title;
  String detail;
  double amount;
  String status;
  DateTime date;

  // Financial details
  double budget;
  double usedAmount;
  double paidAmount;
  double incomeAmount;
  double debtAmount;

  // Financial ownership
  String scope;
  String department;
  String projectName;

  BusinessRecord({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.detail,
    required this.amount,
    required this.status,
    required this.date,
    this.budget = 0,
    this.usedAmount = 0,
    this.paidAmount = 0,
    this.incomeAmount = 0,
    this.debtAmount = 0,
    this.scope = 'company',
    this.department = '',
    this.projectName = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'moduleId': moduleId,
    'title': title,
    'detail': detail,
    'amount': amount,
    'status': status,
    'date': date.toIso8601String(),
    'budget': budget,
    'usedAmount': usedAmount,
    'paidAmount': paidAmount,
    'incomeAmount': incomeAmount,
    'debtAmount': debtAmount,
    'scope': scope,
    'department': department,
    'projectName': projectName,
  };

  factory BusinessRecord.fromJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;

    return BusinessRecord(
      id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      moduleId: '${j['moduleId'] ?? 'finance'}',
      title: '${j['title'] ?? ''}',
      detail: '${j['detail'] ?? ''}',
      amount: n('amount'),
      status: '${j['status'] ?? 'รอดำเนินการ'}',
      date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
      budget: n('budget'),
      usedAmount: n('usedAmount'),
      paidAmount: n('paidAmount'),
      incomeAmount: n('incomeAmount'),
      debtAmount: n('debtAmount'),
      scope: '${j['scope'] ?? 'company'}',
      department: '${j['department'] ?? ''}',
      projectName: '${j['projectName'] ?? ''}',
    );
  }
}

// ============================================================
// COMPANY FINANCE
// ============================================================

class CompanyFinance {
  double registeredCapital;
  double paidCapital;
  double ownerInvestment;
  double shareholderInvestment;
  double cash;
  double bank;

  CompanyFinance({
    this.registeredCapital = 0,
    this.paidCapital = 0,
    this.ownerInvestment = 0,
    this.shareholderInvestment = 0,
    this.cash = 0,
    this.bank = 0,
  });

  double get totalCapital => ownerInvestment + shareholderInvestment;

  double get liquidAssets => cash + bank;

  Map<String, dynamic> toJson() => {
    'registeredCapital': registeredCapital,
    'paidCapital': paidCapital,
    'ownerInvestment': ownerInvestment,
    'shareholderInvestment': shareholderInvestment,
    'cash': cash,
    'bank': bank,
  };

  factory CompanyFinance.fromJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return CompanyFinance(
      registeredCapital: n('registeredCapital'),
      paidCapital: n('paidCapital'),
      ownerInvestment: n('ownerInvestment'),
      shareholderInvestment: n('shareholderInvestment'),
      cash: n('cash'),
      bank: n('bank'),
    );
  }
}

// ============================================================
// APP
// ============================================================

String monthText(DateTime date) {
  return DateFormat('MMMM yyyy', 'th_TH').format(date);
}

class SkyBusinessApp extends StatelessWidget {
  const SkyBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKY BUSINESS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          surface: panel,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel2,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15, vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cyan),
          ),
        ),
      ),
      home: AuthGate(
     appBuilder: (context) => const BusinessHome(),
      ),
    );
  }
}

// ============================================================
// HOME CONTROLLER
// ============================================================

class BusinessHome extends StatefulWidget {
  const BusinessHome({super.key});

  @override
  State<BusinessHome> createState() => _BusinessHomeState();
}

class _BusinessHomeState extends State<BusinessHome> {
  final List<BusinessRecord> records = [];
  CompanyFinance company = CompanyFinance();

  int selected = -1;
  bool loading = true;
  String search = '';

  static const storageKey = 'sky_business_premium_v3';
  static const companyKey = 'sky_business_company_finance_v1';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = prefs.getString(storageKey);

      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          records.addAll(decoded.whereType<Map>().map(
            (e) => BusinessRecord.fromJson(Map<String, dynamic>.from(e)),
          ));
        }
      } else {
        // Import old financial records.
        final old = prefs.getString('sky_transactions');
        if (old != null) {
          final decoded = jsonDecode(old);
          if (decoded is List) {
            for (final row in decoded.whereType<Map>()) {
              final e = Map<String, dynamic>.from(row);
              records.add(BusinessRecord(
                id: '${e['id'] ?? DateTime.now().microsecondsSinceEpoch}',
                moduleId: 'finance',
                title: '${e['title'] ?? 'รายการเดิม'}',
                detail: '${e['category'] ?? ''} ${e['note'] ?? ''}'.trim(),
                amount: (e['amount'] as num?)?.toDouble() ?? 0,
                status: e['type'] == 'income' ? 'รายรับ' : 'รายจ่าย',
                date: DateTime.tryParse('${e['date']}') ?? DateTime.now(),
              ));
            }
          }
        }

        // Import old installment data.
        final oldLoans = prefs.getString('sky_installments');
        if (oldLoans != null) {
          final decoded = jsonDecode(oldLoans);
          if (decoded is List) {
            for (final row in decoded.whereType<Map>()) {
              final e = Map<String, dynamic>.from(row);
              final months = (e['months'] as num?)?.toInt() ?? 0;
              final paid = (e['paidMonths'] as num?)?.toInt() ?? 0;
              final monthly = (e['monthly'] as num?)?.toDouble() ?? 0;
              records.add(BusinessRecord(
                id: '${e['id'] ?? DateTime.now().microsecondsSinceEpoch}',
                moduleId: 'loans',
                title: '${e['title'] ?? 'สัญญาเดิม'}',
                detail: 'ชำระแล้ว $paid/$months งวด',
                amount: monthly * (months - paid).clamp(0, months),
                paidAmount: monthly * paid,
                status: paid >= months ? 'ชำระครบ' : 'กำลังผ่อน',
                date: DateTime.tryParse('${e['startDate']}') ?? DateTime.now(),
              ));
            }
          }
        }

        if (records.isNotEmpty) await saveData();
      }

      final companyData = prefs.getString(companyKey);
      if (companyData != null) {
        company = CompanyFinance.fromJson(
          Map<String, dynamic>.from(jsonDecode(companyData)),
        );
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(records.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(companyKey, jsonEncode(company.toJson()));
  }

  // ==========================================================
  // COMPANY FINANCIAL CALCULATIONS
  // ==========================================================

  double get income => records
      .where((e) => e.moduleId == 'finance' && e.status == 'รายรับ')
      .fold(0, (s, e) => s + e.amount);

  double get expense => records
      .where((e) => e.moduleId == 'finance' && e.status == 'รายจ่าย')
      .fold(0, (s, e) => s + e.amount);

  double get balance => income - expense;

  double get monthlyIncome {
    final now = DateTime.now();
    return records.where((e) =>
      e.moduleId == 'finance' &&
      e.status == 'รายรับ' &&
      e.date.year == now.year &&
      e.date.month == now.month
    ).fold(0, (s, e) => s + e.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return records.where((e) =>
      e.moduleId == 'finance' &&
      e.status == 'รายจ่าย' &&
      e.date.year == now.year &&
      e.date.month == now.month
    ).fold(0, (s, e) => s + e.amount);
  }

  double get monthlyBalance => monthlyIncome - monthlyExpense;

  double get totalBudget => moduleTotal('budget');

  double get budgetUsed => records
      .where((e) => e.moduleId == 'budget')
      .fold(0, (s, e) => s + e.usedAmount);

  double get budgetRemaining => totalBudget - budgetUsed;

  double get invoiceTotal => moduleTotal('invoices');

  double get invoicePaid => moduleStatusTotal('invoices', 'ชำระแล้ว');

  double get invoiceOutstanding => records
      .where((e) =>
        e.moduleId == 'invoices' &&
        e.status != 'ชำระแล้ว' &&
        e.status != 'ร่าง'
      )
      .fold(0, (s, e) => s + e.amount);

  double get salesTotal => records
      .where((e) =>
        e.moduleId == 'sales' &&
        e.status != 'ยกเลิก'
      )
      .fold(0, (s, e) => s + e.amount);

  double get payrollTotal => moduleTotal('payroll');

  double get payrollPaid => moduleStatusTotal('payroll', 'จ่ายแล้ว');

  double get payrollPending =>
      moduleStatusTotal('payroll', 'รอจ่าย');

  double get assetTotal =>
      records.where((e) => e.moduleId == 'assets' &&
        e.status != 'จำหน่ายแล้ว'
      ).fold(0, (s, e) => s + e.amount);

  double get loanRemaining =>
      records.where((e) => e.moduleId == 'loans')
        .fold(0, (s, e) => s + e.amount);

  double get loanPaid =>
      records.where((e) => e.moduleId == 'loans')
        .fold(0, (s, e) => s + e.paidAmount);

  double moduleTotal(String id) => records
      .where((e) => e.moduleId == id)
      .fold(0, (s, e) => s + e.amount);

  double moduleStatusTotal(String id, String status) => records
      .where((e) => e.moduleId == id && e.status == status)
      .fold(0, (s, e) => s + e.amount);

  int moduleCount(String id) =>
      records.where((e) => e.moduleId == id).length;

  // Project calculations.
  double projectBudget(BusinessRecord p) => p.budget;

  double projectUsed(BusinessRecord p) => p.usedAmount;

  double projectRemaining(BusinessRecord p) =>
      p.budget - p.usedAmount;

  double projectPercent(BusinessRecord p) =>
      p.budget <= 0 ? 0 : (p.usedAmount / p.budget).clamp(0.0, 1.0);

  // Department financial calculations.
  Map<String, double> departmentExpenses() {
    final result = <String, double>{};

    for (final r in records.where((e) =>
        e.moduleId == 'finance' && e.status == 'รายจ่าย')) {
      final name = r.department.trim().isEmpty
          ? 'ไม่ระบุแผนก'
          : r.department.trim();
      result[name] = (result[name] ?? 0) + r.amount;
    }

    return result;
  }

  List<BusinessRecord> get filteredRecords {
    if (selected < 0 || selected >= modules.length) return [];

    final id = modules[selected].id;

    final list = records.where((e) => e.moduleId == id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (search.trim().isEmpty) return list;

    final q = search.toLowerCase();

    return list.where((e) =>
      e.title.toLowerCase().contains(q) ||
      e.detail.toLowerCase().contains(q) ||
      e.status.toLowerCase().contains(q) ||
      e.department.toLowerCase().contains(q) ||
      e.projectName.toLowerCase().contains(q) ||
      e.amount.toString().contains(q)
    ).toList();
  }

  // ==========================================================
  // RECORD OPERATIONS
  // ==========================================================

  Future<void> openRecordForm(
    BusinessModule module, {
    BusinessRecord? record,
  }) async {
    final result = await showModalBottomSheet<BusinessRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordForm(module: module, record: record),
    );

    if (result == null) return;

    setState(() {
      final index = records.indexWhere((e) => e.id == result.id);
      if (index >= 0) {
        records[index] = result;
      } else {
        records.insert(0, result);
      }
    });

    await saveData();
  }

  Future<void> deleteRecord(BusinessRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${record.title}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => records.removeWhere((e) => e.id == record.id));
    await saveData();
  }

  Future<void> editCompanyFinance() async {
    final result = await showDialog<CompanyFinance>(
      context: context,
      builder: (_) => CompanyFinanceDialog(initial: company),
    );

    if (result == null) return;

    setState(() => company = result);
    await saveData();
    showMessage('บันทึกข้อมูลการเงินบริษัทแล้ว');
  }

  // ==========================================================
  // BACKUP AND RESTORE
  // ==========================================================

  Future<void> exportBackup() async {
    final data = const JsonEncoder.withIndent('  ').convert({
      'version': 2,
      'records': records.map((e) => e.toJson()).toList(),
      'companyFinance': company.toJson(),
    });

    await Clipboard.setData(ClipboardData(text: data));

    if (mounted) showMessage('คัดลอกข้อมูลสำรองเรียบร้อยแล้ว');
  }

  Future<void> importBackup() async {
    final controller = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text('กู้คืนข้อมูล'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'วาง JSON Backup ที่นี่',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('กู้คืน'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      controller.dispose();
      return;
    }

    try {
      final decoded = jsonDecode(controller.text);
      List<dynamic> rawRecords;

      CompanyFinance? importedCompany;

      // New backup format.
      if (decoded is Map) {
        rawRecords = decoded['records'] is List
            ? decoded['records']
            : [];

        if (decoded['companyFinance'] is Map) {
          importedCompany = CompanyFinance.fromJson(
            Map<String, dynamic>.from(decoded['companyFinance']),
          );
        }
      } else if (decoded is List) {
        // Old backup format.
        rawRecords = decoded;
      } else {
        throw const FormatException('รูปแบบข้อมูลไม่ถูกต้อง');
      }

      final imported = rawRecords
          .whereType<Map>()
          .map((e) => BusinessRecord.fromJson(
            Map<String, dynamic>.from(e),
          ))
          .where((e) => modules.any((m) => m.id == e.moduleId))
          .toList();

      if (imported.isEmpty && importedCompany == null) {
        throw const FormatException('ไม่พบข้อมูลที่สามารถกู้คืนได้');
      }

      setState(() {
        records
          ..clear()
          ..addAll(imported);

        if (importedCompany != null) {
         company = importedCompany;
        }
      });

      await saveData();

      if (mounted) {
        showMessage('กู้คืนข้อมูล ${imported.length} รายการแล้ว');
      }
    } catch (e) {
      if (mounted) showMessage('กู้คืนไม่สำเร็จ: $e');
    } finally {
      controller.dispose();
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: panel2,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void navigate(int index) {
    setState(() {
      selected = index;
      search = '';
    });
  }

  // ==========================================================
  // MAIN UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      drawer: wide ? null : _buildDrawer(),
      appBar: _buildAppBar(wide),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: cyan))
          : Row(
              children: [
                if (wide) _buildSideNavigation(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(selected),
                      child: selected == -1
                          ? _dashboard()
                          : _modulePage(modules[selected]),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: selected >= 0 &&
              selected != 14 && selected != 15
          ? FloatingActionButton.extended(
              backgroundColor: cyan,
              foregroundColor: navy,
              onPressed: () => openRecordForm(modules[selected]),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'เพิ่มข้อมูล',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool wide) {
    return AppBar(
      backgroundColor: navy,
      elevation: 0,
      titleSpacing: wide ? 20 : 0,
      title: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cyan, blue]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: navy),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SKY BUSINESS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                'BUSINESS COMMAND CENTER',
                style: TextStyle(
                  fontSize: 8,
                  color: cyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'หน้าหลัก',
          onPressed: () => navigate(-1),
          icon: const Icon(Icons.home_outlined),
        ),
        IconButton(
          tooltip: 'การเงิน',
          onPressed: () => navigate(0),
          icon: const Icon(Icons.account_balance_wallet_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: panel,
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'BUSINESS COMMAND',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            _navTile(-1, Icons.dashboard_rounded, 'Dashboard'),
            const Divider(color: Colors.white12),
            for (int i = 0; i < modules.length; i++)
              _navTile(i, modules[i].icon, modules[i].name),
          ],
        ),
      ),
    );
  }

  Widget _navTile(int index, IconData icon, String title) {
    final active = selected == index;
    return ListTile(
      selected: active,
      selectedTileColor: cyan.withOpacity(.09),
      leading: Icon(icon, color: active ? cyan : Colors.white54),
      title: Text(
        title,
        style: TextStyle(
          color: active ? cyan : Colors.white70,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
        navigate(index);
      },
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 235,
      color: const Color(0xFF0C1422),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _sideItem(-1, Icons.dashboard_rounded, 'Dashboard'),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Text(
              'BUSINESS SYSTEMS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (int i = 0; i < modules.length; i++)
            _sideItem(i, modules[i].icon, modules[i].name),
        ],
      ),
    );
  }

  Widget _sideItem(int index, IconData icon, String label) {
    final active = selected == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => navigate(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: active ? cyan.withOpacity(.11) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: active ? cyan : Colors.white54),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? cyan : Colors.white70,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // REUSABLE FINANCIAL COMPONENTS
  // ==========================================================

  Widget heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.w900,
        )),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(
          color: Colors.white54, fontSize: 11,
        )),
      ],
    );
  }

  Widget metric(
    String title,
    double value,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(
            color: Colors.white54, fontSize: 11,
          )),
          const SizedBox(height: 5),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              money(value),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(
              color: Colors.white38, fontSize: 10,
            )),
          ],
        ],
      ),
    );
  }

  Widget miniMetric(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              color: Colors.white54, fontSize: 10,
            )),
            const SizedBox(height: 5),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                money(value),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          )),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget valueRow(String label, num value, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 12,
          ))),
          Text(money(value), style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          )),
        ],
      ),
    );
  }

  Widget progressRow(
    String label,
    double used,
    double total,
    Color color,
  ) {
    final p = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold,
            ))),
            Text('${(p * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: Colors.white10,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text('${money(used)} / ${money(total)}',
          style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  // ==========================================================
  // DASHBOARD
  // ==========================================================

  Widget _dashboard() {
    final recent = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1050 ? 4 :
            constraints.maxWidth > 600 ? 2 : 1;

        return ListView(
          key: const PageStorageKey('dashboard'),
          padding: const EdgeInsets.all(20),
          children: [
            _heroBanner(),
            const SizedBox(height: 25),

            heading('Company Financial Overview',
                'ภาพรวมทางการเงินระดับบริษัท'),
            const SizedBox(height: 13),

            GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: count == 1 ? 2.2 : 1.65,
              children: [
                metric('รายรับทั้งหมด', income, green,
                    Icons.trending_up_rounded),
                metric('รายจ่ายทั้งหมด', expense, red,
                    Icons.trending_down_rounded),
                metric('กำไร / ขาดทุนจากรายการ', balance,
                    balance >= 0 ? cyan : red,
                    Icons.account_balance_wallet_rounded),
                metric('เงินสดและธนาคาร', company.liquidAssets,
                    blue, Icons.account_balance_rounded),
              ],
            ),

            const SizedBox(height: 22),

            sectionCard(
              title: 'COMPANY CAPITAL',
              color: cyan,
              children: [
                valueRow('เงินทุนจดทะเบียน',
                    company.registeredCapital),
                valueRow('เงินทุนชำระแล้ว',
                    company.paidCapital, color: green),
                valueRow('เงินลงทุนจากเจ้าของ',
                    company.ownerInvestment),
                valueRow('เงินลงทุนจากผู้ถือหุ้น',
                    company.shareholderInvestment),
                valueRow('เงินทุนจากการลงทุนรวม',
                    company.totalCapital, color: cyan),
                const Divider(color: Colors.white12),
                valueRow('เงินสดในบริษัท',
                    company.cash, color: green),
                valueRow('เงินในบัญชีธนาคาร',
                    company.bank, color: blue),
                valueRow('เงินสดและเงินฝากรวม',
                    company.liquidAssets, color: cyan),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: editCompanyFinance,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('แก้ไขข้อมูลเงินทุนบริษัท'),
                  ),
                ),
              ],
            ),

            heading('Monthly Financial Overview',
                'ผลการดำเนินงานเดือนปัจจุบัน'),
            const SizedBox(height: 13),

            sectionCard(
              title: 'MONTHLY PERFORMANCE',
              color: purple,
              children: [
                Text(monthText(DateTime.now()),
                    style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 12),
                valueRow('รายรับเดือนนี้',
                    monthlyIncome, color: green),
                valueRow('รายจ่ายเดือนนี้',
                    monthlyExpense, color: red),
                const Divider(color: Colors.white12),
                valueRow('ยอดสุทธิเดือนนี้',
                    monthlyBalance,
                    color: monthlyBalance >= 0 ? cyan : red),
              ],
            ),

            heading('Business Financial Position',
                'มูลค่าทางการเงินแยกตามระบบ'),
            const SizedBox(height: 13),

            GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: count == 1 ? 2.2 : 1.65,
              children: [
                metric('งบประมาณทั้งหมด', totalBudget, purple,
                    Icons.pie_chart_rounded),
                metric('งบประมาณคงเหลือ', budgetRemaining, cyan,
                    Icons.savings_rounded),
                metric('ยอดใบแจ้งหนี้', invoiceTotal, orange,
                    Icons.receipt_long_rounded),
                metric('ยอดค้างชำระ', invoiceOutstanding, red,
                    Icons.pending_actions_rounded),
                metric('ยอดขาย', salesTotal, green,
                    Icons.point_of_sale_rounded),
                metric('เงินเดือนทั้งหมด', payrollTotal, blue,
                    Icons.payments_rounded),
                metric('มูลค่าทรัพย์สิน', assetTotal, orange,
                    Icons.devices_rounded),
                metric('หนี้สินคงเหลือ', loanRemaining, red,
                    Icons.credit_score_rounded),
              ],
            ),

            const SizedBox(height: 24),

            heading('Project Financial Overview',
                'งบประมาณและค่าใช้จ่ายแยกตามโครงการ'),
            const SizedBox(height: 12),

            if (moduleCount('projects') == 0)
              const EmptyState(text: 'ยังไม่มีข้อมูลโครงการ')
            else
              ...records.where((e) => e.moduleId == 'projects')
                  .map(_projectCard),

            const SizedBox(height: 20),

            heading('Department Financial Overview',
                'รายจ่ายแยกตามแผนก'),
            const SizedBox(height: 12),

            ...departmentExpenses().entries.map((e) =>
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_center,
                        color: cyan, size: 19),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key)),
                    Text(money(e.value), style: const TextStyle(
                      color: red, fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            heading('Business Applications',
                '17 ระบบบริหารจัดการธุรกิจ'),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: count == 1 ? 3.2 : 1.65,
              ),
              itemBuilder: (_, i) => _moduleCard(i),
            ),

            const SizedBox(height: 24),

            heading('Recent Activity', 'รายการล่าสุด'),
            const SizedBox(height: 12),

            if (recent.isEmpty)
              const EmptyState(text: 'ยังไม่มีข้อมูลในระบบ')
            else
              ...recent.take(5).map(_recordTile),

            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _heroBanner() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12364E),
            Color(0xFF14243D),
            Color(0xFF11172C),
          ],
        ),
        border: Border.all(color: cyan.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.circle, color: green, size: 9),
              SizedBox(width: 7),
              Text('SYSTEM ONLINE', style: TextStyle(
                color: green, fontSize: 10, fontWeight: FontWeight.bold,
              )),
              Spacer(),
              Icon(Icons.bolt_rounded, color: cyan, size: 25),
            ],
          ),
          const SizedBox(height: 25),
          const Text('BUSINESS COMMAND',
              style: TextStyle(color: Colors.white54,
                  fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 7),
          const Text('Control Your Business.',
              style: TextStyle(fontSize: 25,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          const Text('จัดการธุรกิจของคุณจากศูนย์กลางเดียว',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 25),
          const Text('NET FINANCIAL RESULT',
              style: TextStyle(color: Colors.white54,
                  fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(money(balance),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: balance >= 0 ? Colors.white : red,
              )),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              miniMetric('INCOME', income, green),
              const SizedBox(width: 10),
              miniMetric('EXPENSE', expense, red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleCard(int index) {
    final m = modules[index];
    final count = moduleCount(m.id);
    final total = moduleTotal(m.id);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => navigate(index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: m.color.withOpacity(.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(m.icon, color: m.color, size: 23),
                const Spacer(),
                Text('$count รายการ', style: TextStyle(
                  color: m.color, fontSize: 10,
                )),
              ],
            ),
            Text(m.name, style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14,
            )),
            if (m.amount)
              FittedBox(
                child: Text(money(total), style: TextStyle(
                  color: m.color, fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
              )
            else
              Text(m.english, style: const TextStyle(
                color: Colors.white38, fontSize: 9,
              )),
          ],
        ),
      ),
    );
  }

  Widget _projectCard(BusinessRecord p) {
  final remaining = projectRemaining(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: purple.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.title, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14,
              ))),
              Text(p.status, style: const TextStyle(
                color: purple, fontSize: 10,
              )),
            ],
          ),
          const SizedBox(height: 12),
          valueRow('งบประมาณโครงการ', p.budget, color: purple),
          valueRow('ใช้ไปแล้ว', p.usedAmount, color: red),
          valueRow('งบประมาณคงเหลือ', remaining,
              color: remaining >= 0 ? green : red),
          valueRow('รายรับจากโครงการ', p.incomeAmount, color: green),
          valueRow('หนี้สินโครงการ', p.debtAmount, color: red),
          progressRow('สัดส่วนการใช้งบประมาณ',
              p.usedAmount, p.budget, cyan),
        ],
      ),
    );
  }

  // ==========================================================
  // MODULE PAGES
  // ==========================================================

  Widget _modulePage(BusinessModule module) {
    if (module.id == 'reports') return _reportsPage();
    if (module.id == 'settings') return _settingsPage();

    final list = filteredRecords;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(module.icon, color: module.color, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.name, style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                      )),
                      Text(module.english, style: const TextStyle(
                        color: Colors.white54, fontSize: 10,
                      )),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาข้อมูลในระบบ...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              if (module.amount) ...[
                const SizedBox(height: 13),
                _moduleSummary(module),
              ],
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  text: 'ไม่พบข้อมูลในระบบ\nกดปุ่มเพิ่มข้อมูลเพื่อเริ่มต้น',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _recordTile(list[i]),
                ),
        ),
      ],
    );
  }

  Widget _moduleSummary(BusinessModule m) {
    switch (m.id) {
      case 'finance':
        return Row(children: [
          miniMetric('รายรับ', income, green),
          const SizedBox(width: 7),
          miniMetric('รายจ่าย', expense, red),
          const SizedBox(width: 7),
          miniMetric('สุทธิ', balance, cyan),
        ]);

      case 'budget':
        return Row(children: [
          miniMetric('งบทั้งหมด', totalBudget, purple),
          const SizedBox(width: 7),
          miniMetric('ใช้ไป', budgetUsed, red),
          const SizedBox(width: 7),
          miniMetric('คงเหลือ', budgetRemaining, green),
        ]);

      case 'invoices':
        return Row(children: [
          miniMetric('ยอดรวม', invoiceTotal, orange),
          const SizedBox(width: 7),
          miniMetric('ชำระแล้ว', invoicePaid, green),
          const SizedBox(width: 7),
          miniMetric('ยอดค้าง', invoiceOutstanding, red),
        ]);

      case 'sales':
        return Row(children: [
          miniMetric('ยอดขาย', salesTotal, green),
          const SizedBox(width: 7),
          miniMetric('จำนวนคำสั่งซื้อ',
              moduleCount('sales').toDouble(), cyan),
        ]);

      case 'payroll':
        return Row(children: [
          miniMetric('เงินเดือนรวม', payrollTotal, blue),
          const SizedBox(width: 7),
          miniMetric('จ่ายแล้ว', payrollPaid, green),
          const SizedBox(width: 7),
          miniMetric('รอจ่าย', payrollPending, red),
        ]);

      case 'projects':
        return Row(children: [
          miniMetric('มูลค่าโครงการ', moduleTotal('projects'), purple),
          const SizedBox(width: 7),
          miniMetric('จำนวนโครงการ',
              moduleCount('projects').toDouble(), cyan),
        ]);

      case 'inventory':
        return Row(children: [
          miniMetric('มูลค่าสินค้า', moduleTotal('inventory'), orange),
          const SizedBox(width: 7),
          miniMetric('จำนวนรายการ',
              moduleCount('inventory').toDouble(), cyan),
        ]);

      case 'assets':
        return Row(children: [
          miniMetric('มูลค่าทรัพย์สิน', assetTotal, orange),
          const SizedBox(width: 7),
          miniMetric('จำนวนรายการ',
              moduleCount('assets').toDouble(), cyan),
        ]);

      case 'loans':
        return Row(children: [
          miniMetric('หนี้คงเหลือ', loanRemaining, red),
          const SizedBox(width: 7),
          miniMetric('ชำระแล้ว', loanPaid, green),
        ]);

      default:
        return Row(children: [
          miniMetric('มูลค่ารวม', moduleTotal(m.id), m.color),
          const SizedBox(width: 7),
          miniMetric('จำนวนรายการ',
              moduleCount(m.id).toDouble(), cyan),
        ]);
    }
  }

  // ==========================================================
  // RECORD DISPLAY
  // ==========================================================

  Widget _recordTile(BusinessRecord r) {
    final m = modules.firstWhere(
      (e) => e.id == r.moduleId,
      orElse: () => modules.first,
    );

    final isIncome = r.moduleId == 'finance' && r.status == 'รายรับ';
    final isExpense = r.moduleId == 'finance' && r.status == 'รายจ่าย';

    final color = isIncome ? green : isExpense ? red : m.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7,
        ),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(m.icon, color: color),
        ),
        title: Text(r.title, style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 13,
        )),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${m.name} • ${r.status} • ${dateText(r.date)}',
                style: const TextStyle(
                  color: Colors.white54, fontSize: 10,
                ),
              ),
              if (r.detail.isNotEmpty)
                Text(r.detail, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38, fontSize: 10,
                  )),
              if (r.scope == 'project' && r.projectName.isNotEmpty)
                Text('โครงการ: ${r.projectName}',
                  style: const TextStyle(color: purple, fontSize: 10)),
              if (r.department.isNotEmpty)
                Text('แผนก: ${r.department}',
                  style: const TextStyle(color: cyan, fontSize: 10)),
              if (r.moduleId == 'projects') ...[
                Text('งบประมาณ: ${money(r.budget)}',
                  style: const TextStyle(color: purple, fontSize: 10)),
                Text('ใช้ไป: ${money(r.usedAmount)}  |  คงเหลือ: ${money(projectRemaining(r))}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ],
          ),
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 115,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (m.amount)
                FittedBox(
                  child: Text(
                    money(r.amount),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert,
                    color: Colors.white54, size: 19),
                onSelected: (v) {
                  if (v == 'edit') openRecordForm(m, record: r);
                  if (v == 'delete') deleteRecord(r);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit',
                      child: Text('แก้ไขข้อมูล')),
                  PopupMenuItem(value: 'delete',
                      child: Text('ลบข้อมูล')),
                ],
              ),
            ],
          ),
        ),
        onTap: () => openRecordForm(m, record: r),
      ),
    );
  }

  // ==========================================================
  // REPORTS
  // ==========================================================

  Widget _reportsPage() {
    final categories = <String, double>{};

    for (final r in records.where((e) =>
        e.moduleId == 'finance' && e.status == 'รายจ่าย')) {
      final category = r.detail.trim().isEmpty
          ? 'ไม่ระบุหมวดหมู่'
          : r.detail.split('/').first.trim();

      categories[category] = (categories[category] ?? 0) + r.amount;
    }

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final departments = departmentExpenses().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Business Analytics',
            'รายงานวิเคราะห์ข้อมูลทางการเงิน'),
        const SizedBox(height: 17),

        sectionCard(
          title: 'COMPANY FINANCIAL REPORT',
          color: cyan,
          children: [
            valueRow('รายรับทั้งหมด', income, color: green),
            valueRow('รายจ่ายทั้งหมด', expense, color: red),
            const Divider(color: Colors.white12),
            valueRow('กำไร / ขาดทุน', balance,
                color: balance >= 0 ? cyan : red),
            valueRow('เงินทุนบริษัท', company.totalCapital,
                color: purple),
            valueRow('เงินสดและธนาคาร', company.liquidAssets,
                color: blue),
          ],
        ),

        sectionCard(
          title: 'MONTHLY REPORT',
          color: purple,
          children: [
            Text(monthText(DateTime.now()),
                style: const TextStyle(color: Colors.white54)),
            valueRow('รายรับเดือนนี้', monthlyIncome, color: green),
            valueRow('รายจ่ายเดือนนี้', monthlyExpense, color: red),
            valueRow('ยอดสุทธิเดือนนี้', monthlyBalance,
                color: monthlyBalance >= 0 ? cyan : red),
          ],
        ),

        sectionCard(
          title: 'BUDGET REPORT',
          color: orange,
          children: [
            valueRow('งบประมาณรวม', totalBudget, color: purple),
            valueRow('ใช้ไปแล้ว', budgetUsed, color: red),
            valueRow('คงเหลือ', budgetRemaining, color: green),
            progressRow('การใช้งบประมาณ',
                budgetUsed, totalBudget, orange),
          ],
        ),

        sectionCard(
          title: 'INVOICE REPORT',
          color: orange,
          children: [
            valueRow('ใบแจ้งหนี้ทั้งหมด', invoiceTotal),
            valueRow('ชำระแล้ว', invoicePaid, color: green),
            valueRow('ค้างชำระ', invoiceOutstanding, color: red),
          ],
        ),

        sectionCard(
          title: 'PAYROLL REPORT',
          color: green,
          children: [
            valueRow('เงินเดือนรวม', payrollTotal),
            valueRow('จ่ายแล้ว', payrollPaid, color: green),
            valueRow('รอจ่าย', payrollPending, color: red),
          ],
        ),

        sectionCard(
          title: 'ASSET & LIABILITY REPORT',
          color: blue,
          children: [
            valueRow('ทรัพย์สิน', assetTotal, color: green),
            valueRow('หนี้สินคงเหลือ', loanRemaining, color: red),
            valueRow('หนี้ที่ชำระแล้ว', loanPaid, color: cyan),
          ],
        ),

        heading('Expense Breakdown',
            'สัดส่วนรายจ่ายแยกตามหมวดหมู่'),
        const SizedBox(height: 13),

        if (sorted.isEmpty)
          const EmptyState(text: 'ยังไม่มีข้อมูลรายจ่าย')
        else
          ...sorted.map((e) {
            final p = expense <= 0
                ? 0.0
                : (e.value / expense).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: Text(e.key)),
                    Text(money(e.value), style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
                  ]),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: p,
                    minHeight: 7,
                    backgroundColor: Colors.white10,
                    color: cyan,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${(p * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: cyan, fontSize: 10,
                        )),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 20),

        heading('Department Financial Report',
            'รายจ่ายของแต่ละแผนก'),
        const SizedBox(height: 12),

        if (departments.isEmpty)
          const EmptyState(text: 'ยังไม่มีข้อมูลรายจ่ายแผนก')
        else
          ...departments.map((e) => valueRow(
            e.key, e.value, color: red,
          )),

        const SizedBox(height: 20),

        heading('Project Financial Report',
            'งบประมาณและการใช้จ่ายของโครงการ'),
        const SizedBox(height: 12),

        ...records.where((e) => e.moduleId == 'projects')
            .map(_projectCard),

        const SizedBox(height: 20),

        heading('System Activity',
            'จำนวนข้อมูลและมูลค่าของแต่ละระบบ'),
        const SizedBox(height: 12),

        ...modules.where((m) =>
            m.id != 'reports' && m.id != 'settings').map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(m.icon, color: m.color, size: 19),
                const SizedBox(width: 10),
                Expanded(child: Text(m.name)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${moduleCount(m.id)} รายการ',
                        style: TextStyle(
                          color: m.color,
                          fontWeight: FontWeight.bold,
                        )),
                    if (m.amount)
                      Text(money(moduleTotal(m.id)),
                          style: const TextStyle(
                            color: Colors.white54, fontSize: 10,
                          )),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),
        const Text(
          'หมายเหตุ: รายงานคำนวณจากข้อมูลที่บันทึกในแอป '
          'ไม่ใช่งบการเงินที่ผ่านการตรวจสอบตามมาตรฐานบัญชี '
          'ยอดเงินสดและเงินธนาคารเป็นยอดที่ผู้ใช้กรอกเอง '
          'และไม่เชื่อมต่อกับธนาคาร',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  Widget _settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('System Control',
            'ตั้งค่าและจัดการข้อมูล SKY BUSINESS'),
        const SizedBox(height: 18),

        sectionCard(
          title: 'COMPANY FINANCE SETTINGS',
          color: cyan,
          children: [
            valueRow('เงินทุนจดทะเบียน', company.registeredCapital),
            valueRow('เงินทุนชำระแล้ว', company.paidCapital),
            valueRow('เงินลงทุนเจ้าของ', company.ownerInvestment),
            valueRow('เงินลงทุนผู้ถือหุ้น', company.shareholderInvestment),
            valueRow('เงินสด', company.cash),
            valueRow('เงินธนาคาร', company.bank),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: editCompanyFinance,
                icon: const Icon(Icons.edit),
                label: const Text('แก้ไขข้อมูลบริษัท'),
              ),
            ),
          ],
        ),

        _settingCard(
          Icons.backup_rounded,
          cyan,
          'Backup Data',
          'คัดลอกข้อมูลทั้งหมดเป็น JSON',
          exportBackup,
        ),
        _settingCard(
          Icons.restore_rounded,
          orange,
          'Restore Data',
          'กู้คืนข้อมูลจาก JSON Backup',
          importBackup,
        ),
        _settingCard(
          Icons.storage_rounded,
          green,
          'Local Storage',
          '${records.length} รายการถูกจัดเก็บในอุปกรณ์',
          null,
        ),

        const SizedBox(height: 20),
        const Text('SYSTEM INFORMATION',
            style: TextStyle(
              color: cyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
              fontSize: 11,
            )),
        const SizedBox(height: 12),
        _infoRow('Application', 'SKY BUSINESS'),
        _infoRow('Architecture', 'Flutter / Dart'),
        _infoRow('Storage', 'SharedPreferences'),
        _infoRow('Modules', '17 Systems'),
        _infoRow('Data Sync', 'Local Only'),
        _infoRow('Cloud Server', 'Not Connected'),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: orange.withOpacity(.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: orange.withOpacity(.2)),
          ),
          child: const Text(
            'ควรสำรองข้อมูลเป็นประจำ ข้อมูลเวอร์ชันนี้ '
            'ยังไม่ได้ซิงก์ไปยัง Cloud หรืออุปกรณ์อื่นโดยอัตโนมัติ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingCard(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(
          fontWeight: FontWeight.bold,
        )),
        subtitle: Text(subtitle, style: const TextStyle(
          color: Colors.white54, fontSize: 11,
        )),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: Colors.white54))),
        Text(value, style: const TextStyle(
          fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }
}

// ============================================================
// COMPANY FINANCE EDITOR
// ============================================================

class CompanyFinanceDialog extends StatefulWidget {
  final CompanyFinance initial;

  const CompanyFinanceDialog({
    super.key,
    required this.initial,
  });

  @override
  State<CompanyFinanceDialog> createState() =>
      _CompanyFinanceDialogState();
}

class _CompanyFinanceDialogState extends State<CompanyFinanceDialog> {
  late final TextEditingController registered;
  late final TextEditingController paid;
  late final TextEditingController owner;
  late final TextEditingController shareholders;
  late final TextEditingController cash;
  late final TextEditingController bank;

  @override
  void initState() {
    super.initState();
    registered = TextEditingController(
        text: widget.initial.registeredCapital.toString());
    paid = TextEditingController(
        text: widget.initial.paidCapital.toString());
    owner = TextEditingController(
        text: widget.initial.ownerInvestment.toString());
    shareholders = TextEditingController(
        text: widget.initial.shareholderInvestment.toString());
    cash = TextEditingController(
        text: widget.initial.cash.toString());
    bank = TextEditingController(
        text: widget.initial.bank.toString());
  }

  @override
  void dispose() {
    registered.dispose();
    paid.dispose();
    owner.dispose();
    shareholders.dispose();
    cash.dispose();
    bank.dispose();
    super.dispose();
  }

  double parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  Widget field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.payments_outlined),
        ),
        validator: (v) {
          final n = double.tryParse(
            (v ?? '').replaceAll(',', '').trim(),
          );
          return n == null || n < 0
              ? 'กรุณากรอกจำนวนเงินที่ถูกต้อง'
              : null;
        },
      ),
    );
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: panel,
      title: const Text('ข้อมูลทางการเงินบริษัท'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field('เงินทุนจดทะเบียน (บาท)', registered),
                field('เงินทุนชำระแล้ว (บาท)', paid),
                field('เงินลงทุนจากเจ้าของ (บาท)', owner),
                field('เงินลงทุนจากผู้ถือหุ้น (บาท)', shareholders),
                const Divider(color: Colors.white12),
                field('เงินสดในบริษัท (บาท)', cash),
                field('เงินในบัญชีธนาคาร (บาท)', bank),
                const Text(
                  'ข้อมูลเหล่านี้เป็นยอดที่กรอกด้วยตนเอง '
                  'ไม่ได้เชื่อมต่อกับธนาคาร',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            Navigator.pop(
              context,
              CompanyFinance(
                registeredCapital: parse(registered),
                paidCapital: parse(paid),
                ownerInvestment: parse(owner),
                shareholderInvestment: parse(shareholders),
                cash: parse(cash),
                bank: parse(bank),
              ),
            );
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

// ============================================================
// RECORD FORM
// ============================================================

class RecordForm extends StatefulWidget {
  final BusinessModule module;
  final BusinessRecord? record;

  const RecordForm({
    super.key,
    required this.module,
    this.record,
  });

  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController detail;
  late final TextEditingController amount;
  late final TextEditingController budget;
  late final TextEditingController used;
  late final TextEditingController paid;
  late final TextEditingController projectIncome;
  late final TextEditingController debt;
  late final TextEditingController department;
  late final TextEditingController projectName;

  late String status;
  late String scope;
  late DateTime date;

  bool get isProject => widget.module.id == 'projects';
  bool get isFinance => widget.module.id == 'finance';
  bool get isBudget => widget.module.id == 'budget';
  bool get isLoan => widget.module.id == 'loans';

  @override
  void initState() {
    super.initState();

    final r = widget.record;

    title = TextEditingController(text: r?.title ?? '');
    detail = TextEditingController(text: r?.detail ?? '');
    amount = TextEditingController(text: r?.amount.toString() ?? '');
    budget = TextEditingController(text: r?.budget.toString() ?? '');
    used = TextEditingController(text: r?.usedAmount.toString() ?? '');
    paid = TextEditingController(text: r?.paidAmount.toString() ?? '');
    projectIncome = TextEditingController(
        text: r?.incomeAmount.toString() ?? '');
    debt = TextEditingController(text: r?.debtAmount.toString() ?? '');
    department = TextEditingController(text: r?.department ?? '');
    projectName = TextEditingController(text: r?.projectName ?? '');

    status = r?.status ?? widget.module.statuses.first;
    scope = r?.scope ?? 'company';
    date = r?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    title.dispose();
    detail.dispose();
    amount.dispose();
    budget.dispose();
    used.dispose();
    paid.dispose();
    projectIncome.dispose();
    debt.dispose();
    department.dispose();
    projectName.dispose();
    super.dispose();
  }

  double parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  Widget input(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 1,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(numeric
              ? Icons.payments_outlined
              : Icons.edit_note_rounded),
        ),
        validator: numeric
            ? (v) {
                final n = double.tryParse(
                  (v ?? '').replaceAll(',', '').trim(),
                );
                return n == null || n < 0
                    ? 'กรุณากรอกจำนวนเงินให้ถูกต้อง'
                    : null;
              }
            : null,
      ),
    );
  }

  Widget financialSection(String heading, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: panel2.withOpacity(.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(
            color: cyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;

    return Container(
      decoration: const BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            19, 13, 19,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(
                    width: 42, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
                  const SizedBox(height: 20),
                  Row(children: [
                    Icon(m.icon, color: m.color, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      widget.record == null
                          ? 'เพิ่ม${m.name}'
                          : 'แก้ไข${m.name}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  input('ชื่อรายการ', title),

                  if (m.amount)
                    financialSection(
                      'FINANCIAL INFORMATION',
                      [
                        input(
                          isProject ? 'มูลค่าโครงการ (บาท)' :
                          isLoan ? 'ยอดหนี้คงเหลือ (บาท)' :
                          'จำนวนเงิน / มูลค่า (บาท)',
                          amount,
                          numeric: true,
                        ),

                        if (isProject) ...[
                          input('งบประมาณที่ได้รับ (บาท)',
                              budget, numeric: true),
                          input('เงินที่ใช้ไปแล้ว (บาท)',
                              used, numeric: true),
                          input('รายรับจากโครงการ (บาท)',
                              projectIncome, numeric: true),
                          input('หนี้สินโครงการ (บาท)',
                              debt, numeric: true),
                        ],

                        if (isBudget) ...[
                          input('งบประมาณที่ใช้ไปแล้ว (บาท)',
                              used, numeric: true),
                        ],

                        if (isLoan) ...[
                          input('ยอดที่ชำระไปแล้ว (บาท)',
                              paid, numeric: true),
                        ],
                      ],
                    ),

                  if (isFinance) ...[
                    financialSection(
                      'FINANCIAL OWNERSHIP',
                      [
                        DropdownButtonFormField<String>(
                          value: scope,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทเงิน',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'company',
                              child: Text('เงินบริษัท'),
                            ),
                            DropdownMenuItem(
                              value: 'project',
                              child: Text('เงินโครงการ'),
                            ),
                            DropdownMenuItem(
                              value: 'department',
                              child: Text('เงินแผนก'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => scope = v);
                          },
                        ),
                        if (scope == 'project')
                          input('ชื่อโครงการที่เกี่ยวข้อง', projectName),
                        if (scope == 'department')
                          input('ชื่อแผนก', department),
                        if (scope == 'company')
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'รายการนี้จะถูกจัดเป็นธุรกรรมของบริษัท',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  if (!isFinance && !isProject)
                    input(m.detailLabel, detail, lines: 2)
                  else if (isProject)
                    input('รายละเอียด / ผู้รับผิดชอบ',
                        detail, lines: 2)
                  else
                    input('หมวดหมู่ / รายละเอียด',
                        detail, lines: 2),

                  if (!isFinance && !isProject &&
                      scope == 'company' &&
                      m.id != 'budget') ...[
                    const SizedBox(height: 0),
                  ],

                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'สถานะรายการ',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                    items: m.statuses.map((e) =>
                      DropdownMenuItem(value: e, child: Text(e))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => status = v);
                    },
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: panel2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: cyan,
                      ),
                      title: const Text('วันที่'),
                      subtitle: Text(dateText(date)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => date = picked);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cyan,
                        foregroundColor: navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

                        final result = BusinessRecord(
                          id: widget.record?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          moduleId: m.id,
                          title: title.text.trim(),
                          detail: detail.text.trim(),
                          amount: m.amount ? parse(amount) : 0,
                          status: status,
                          date: date,
                          budget: isProject || isBudget ? parse(budget) : 0,
                          usedAmount: isProject || isBudget
                              ? parse(used) : 0,
                          paidAmount: isLoan ? parse(paid) : 0,
                          incomeAmount: isProject
                              ? parse(projectIncome) : 0,
                          debtAmount: isProject ? parse(debt) : 0,
                          scope: isFinance ? scope : 'company',
                          department: department.text.trim(),
                          projectName: projectName.text.trim(),
                        );

                        Navigator.pop(context, result);
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('บันทึกข้อมูล',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(
        vertical: 35, horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded,
              color: cyan, size: 40),
          const SizedBox(height: 13),
          const Text('NO DATA FOUND',
              style: TextStyle(
                color: cyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}
