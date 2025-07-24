import 'package:brownskin_app/common/api_service.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:http/http.dart' as http;
import '../../common/widgets.dart';

class SetThresholdAdminPage extends StatefulWidget {
  String token;

  SetThresholdAdminPage({required this.token, super.key});

  @override
  _SetThresholdAdminPageState createState() => _SetThresholdAdminPageState();
}

class _SetThresholdAdminPageState extends State<SetThresholdAdminPage>
    with TickerProviderStateMixin {
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetGoalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String get token => widget.token;

  // page2 용 변수
  String? selectedType;
  String? selectedByproductName;
  String? selectedProvince;
  int selectedIndex = 1;

  bool isLoading = false;
  bool isSuccess = false;
  String? errorMessage;
  String? currentThreshold;

  // 애니메이션 컨트롤러
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
    _targetGoalController.dispose();
    _animationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<bool> setThreshold(String? weight) async {
    if (weight == null || weight.isEmpty) return false;
    try {
      final request = await http.post(
        Uri.parse("$BASE_URL/api/threshold"),
        headers: {'Authorization': 'Token ${widget.token}'},
        body: {
          'type': selectedType,
          'name': selectedByproductName,
          'weight': weight
        },
      );
      if (request.statusCode != 200) {
        errorMessage = '임계값 설정에 실패했습니다.';
        return false;
      }
      await getThreshold(selectedType,selectedByproductName);
      isSuccess = true;
      _successAnimationController.forward();
      return true;
    } catch (e) {
      errorMessage = '네트워크 오류가 발생했습니다.';
    }
    return false;
  }


  Future<void> getThreshold(String? type, String? name) async {
    final raw = await ApiService.fetchMap(url: "$BASE_URL/api/threshold?"+"type=$type&"+"name=$name", token: token);
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
                    buildHeaderCard(
                    title: '임계값 관리',
                    subtitle: '부산물 수집량의 임계값을 설정하여\n효율적인 관리를 시작하세요',
                    icon: Icons.tune,
                  ),
                      const SizedBox(height: 20),
                      _buildSelectionCard(),
                      const SizedBox(height: 20),
                      _buildThresholdCard(),
                      const SizedBox(height: 20),
                      _buildActionButton(),
                      if (isSuccess) ...[
                        const SizedBox(height: 20),
                        buildSuccessCard(_scaleAnimation)
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
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('임계값 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context, 0)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green, Colors.lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
      ),
      actions: [buildLogoutIconButton(context,backgroundColor: Colors.lightGreen)],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    setState(() {selectedIndex = index;});
    if (index == 0) Navigator.pop(context, 0);
  }

  Widget buildHeaderCard({
    required String title, required String subtitle,
    required IconData icon,
    Color iconBgColor = Colors.white, Color iconColor = Colors.white, Gradient? backgroundGradient, Color shadowColor = Colors.green,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: backgroundGradient ?? LinearGradient(colors: [Colors.green, Colors.lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight,),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(50)),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }


  Widget buildIconTitleRow(IconData icon, String title, {Color color = Colors.green}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIconTitleRow(Icons.category, '대상 선택'),
          const SizedBox(height: 20),

          /// 부산물 유형 드롭다운
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
            /// 품목 드롭다운
            CommonDropdownField(
              value: selectedByproductName,
              items: byproductsCategory.where((item) => item['type'] == selectedType)
                  .map((item) => item['name']!)
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
    return buildCard(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4),)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCardTitle(icon: Icons.scale, title: '임계값 설정', iconColor: const Color(0xFF10B981)),
          const SizedBox(height: 20),

          if (currentThreshold != null) ...[
            buildCard(
              color: const Color(0xFF10B981).withOpacity(0.1),
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [],
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 12),
                  Text('현재 설정된 임계값: ${currentThreshold}kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981),),),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0)),),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0)),),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444)),),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            buildErrorMessageCard(errorMessage!)
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
      decoration: BoxDecoration(gradient: canSubmit ? const LinearGradient(colors: [Colors.green, Colors.lightGreen],)
            : null,
        color: canSubmit ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: canSubmit ? [BoxShadow(color: const Color(0xFF667EEA) , blurRadius: 15, offset: const Offset(0, 6))]
            : null,
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

  Widget buildSuccessCard(Animation<double> scaleAnimation) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)],),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0xFF10B981), blurRadius: 15, offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
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

  Widget buildCard({
    required Widget child, Color? color, Gradient? gradient,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    List<BoxShadow>? boxShadow, EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, gradient: gradient, borderRadius: borderRadius, boxShadow: boxShadow,),
      child: child,
    );
  }

  Widget buildCardTitle({
    required IconData icon, required String title,
    Color iconColor = Colors.green, double iconSize = 20,
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

  Widget buildErrorMessageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500))),
        ],
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
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}
