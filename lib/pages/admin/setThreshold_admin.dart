import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/pages/admin/tester.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import '../../common/widgets.dart';

class SetThresholdAdminPage extends StatefulWidget {
  String token;

  SetThresholdAdminPage({required this.token, super.key});

  @override
  _SetThresholdAdminPageState createState() => _SetThresholdAdminPageState();
}

class CommonCards {
  static Widget buildCard({
    required Widget child,
    Color? color, Gradient? gradient,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)), List<BoxShadow>? boxShadow,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, gradient: gradient, borderRadius: borderRadius, boxShadow: boxShadow),
      child: child,
    );
  }

  static Widget buildCardTitle({
    required IconData icon,
    required String title,
    Color iconColor = Colors.brown, double iconSize = 20,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  static Widget buildErrorMessageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.brown.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.brown, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }


  static Widget buildHeaderCard({
    required String title, required String subtitle,
    Gradient? backgroundGradient, Color shadowColor = Colors.brown,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }

  static Widget buildSuccessCard(Animation<double> scaleAnimation) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.brown,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color:Colors.brown, blurRadius: 15, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 24)
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('설정 완료!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('임계값이 성공적으로 설정되었습니다.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SetThresholdAdminPageState extends State<SetThresholdAdminPage> with TickerProviderStateMixin {
  final TextEditingController _currentWeightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? selectedType;
  String? selectedByproductName;
  int selectedIndex = 1;

  bool isLoading = false;
  bool isSuccess = false;
  String? errorMessage;
  String? currentThreshold;

  late AnimationController _animationController;
  late AnimationController _successAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this,);
    _successAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this,);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),);
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _successAnimationController, curve: Curves.elasticOut),);
    _animationController.forward();
    _currentWeightController.addListener(() {setState(() {});});
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _animationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<bool> setThreshold(String? weight) async {
    if (weight == null || weight.isEmpty) return false;

    final response = await ApiService.postWithToken(
      endpoint: '/api/threshold',
      token: widget.token,
      body: {
        'type': selectedType!,
        'name': selectedByproductName!,
        'weight': weight
      },
    );
    if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      await getThreshold(selectedType,selectedByproductName);
      isSuccess = true;
      _successAnimationController.forward();
      return true;
    }
    return false;
  }


  Future<void> getThreshold(String? type, String? name) async {
    final raw = await ApiService.fetchMap(url: "$BASE_URL/api/threshold?"+"type=$type&"+"name=$name", token: widget.token);
    if (raw["weight_float"] != null)  currentThreshold = raw["weight_float"].toString();
    else  currentThreshold = null;
  }


  /* UI 구현 */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CommonCards.buildHeaderCard(title: '임계값 관리', subtitle: '부산물 수집량의 임계값을 설정하여\n효율적인 관리를 시작하세요'),
                      const SizedBox(height: 20),
                      _buildSelectionCard(),
                      const SizedBox(height: 20),
                      _buildThresholdCard(),
                      const SizedBox(height: 20),
                      _buildActionButton(),
                      if (isSuccess) ...[
                        const SizedBox(height: 20),
                        CommonCards.buildSuccessCard(_scaleAnimation)
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: bottomNavigationBar(
        context,
        [
          BottomNavItem(icon: Icons.home, label: '홈', onTap: () => _onItemTapped(context, 0), isSelected: selectedIndex == 0),
          BottomNavItem(icon: Icons.settings_rounded, label: '임계 설정', onTap: () => _onItemTapped(context, 1),isSelected: selectedIndex == 1),
          BottomNavItem(icon: Icons.science_outlined, label: '시연용(임시)', isSelected: selectedIndex == 2, onTap: () => _onItemTapped(context, 2)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('임계값 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      backgroundColor:AppColors.primaryBrown,
      foregroundColor:Colors.white,
      elevation: 0,
      //leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context, 0)),
      flexibleSpace: Container(decoration: const BoxDecoration(color: AppColors.primaryBrown)),
      actions: [
        buildMyPageIconButton(context, widget.token),
        buildLogoutIconButton(context,backgroundColor: AppColors.primaryBrown)
      ],
    );
  }

  Future<void> _onItemTapped(BuildContext context, int index) async {
    setState(() {selectedIndex = index;});
    if (index == 0) Navigator.pop(context, 0);

    if (index == 2) {
      await Navigator.push<int>(context,
          MaterialPageRoute(builder: (context) => Tester()));
    }
    setState(() => selectedIndex = 1);
  }

  Widget buildIconTitleRow(IconData icon, String title, {Color color = AppColors.primaryBrown}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIconTitleRow(Icons.category, '대상 선택'),
          const SizedBox(height: 20),
          CommonDropdownField(
            value: selectedType,
            items: const ["가공", "수확"],
            onChanged: (value) {
              setState(() {
                selectedType = value;
                selectedByproductName = null;
                isSuccess = false;
                _successAnimationController.reset();
              });
            },
            hintText: '부산물 유형 선택',
          ),
          if (selectedType != null) ...[
            const SizedBox(height: 16),
            CommonDropdownField(
              value: selectedByproductName,
              items: byproductsCategory.where((item) => item['type'] == selectedType).map((item) => item['name']!)
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  selectedByproductName = value;
                  isSuccess = false;
                  currentThreshold = null;
                  _successAnimationController.reset();
                });
                await getThreshold(selectedType, value);
                setState(() {});
              },
              hintText: '품목 선택',
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildThresholdCard() {
    return CommonCards.buildCard(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4),)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonCards.buildCardTitle(icon: Icons.scale, title: '임계값 설정', iconColor: Colors.brown),
          const SizedBox(height: 20),

          if (currentThreshold != null) ...[
            CommonCards.buildCard(
              color:  Colors.brown,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [],
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.brown, size: 20),
                  const SizedBox(width: 12),
                  Text('현재 설정된 임계값: ${currentThreshold}kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Row(
            children: [
              Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text('새로운 임계값 (kg)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
              controller: _currentWeightController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return '임계값을 입력해주세요';
                if (double.tryParse(value) == null) return '올바른 숫자를 입력해주세요';
                if (double.parse(value) <= 0) return '0보다 큰 값을 입력해주세요';
                return null;
              },
            decoration: InputDecoration(hintText: '예: 100',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixText: 'kg',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(
                  0xFF855056), width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            CommonCards.buildErrorMessageCard(errorMessage!)
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    bool canSubmit = selectedType != null && selectedByproductName != null && _currentWeightController.text.isNotEmpty;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(gradient: canSubmit ? const LinearGradient(colors: [Colors.brown, Color(0xFF6C4348)]) : null,
        color: canSubmit ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: canSubmit ? [BoxShadow(color:  Color(0xFF6C4348) , blurRadius: 15, offset: const Offset(0, 6))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canSubmit && !isLoading ? _handleSubmit : null,
          child: Center(
            child: isLoading ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: canSubmit ? Colors.white : Colors.grey.shade500, size: 20,),
                const SizedBox(width: 8),
                Text('임계값 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: canSubmit ? Colors.white : Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      String weightValue = _currentWeightController.text;

      setState(() { isLoading = true; });
      bool result = await setThreshold(weightValue);
      setState(() {isLoading = false;});

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('임계값이 성공적으로 설정되었습니다!')],),
            backgroundColor: Colors.brown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}