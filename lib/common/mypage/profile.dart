import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/mypage/set_password.dart';
import 'package:brownskin_app/common/mypage/withdraw.dart';
import 'package:daum_postcode_view/daum_postcode_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../widgets.dart';

class EditProfilePage extends StatefulWidget {
  final String token;
  const EditProfilePage({super.key, required this.token});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Map<String, TextEditingController> _controllers = {};
  Map<String,dynamic> userData = {};

  final _formKey = GlobalKey<FormState>();

  @override void initState() {
    super.initState();
    initController();
  }


  Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.fetchMap(url: '/auth/api-profile', token: widget.token);
  }

  void initController() async {
    final userData = await getProfile();
    _controllers = {
      'id': TextEditingController(text: userData['id']),
      'name': TextEditingController(text: "이름"),
      'phone': TextEditingController(text: "전화번호"),
      'bizNumber': TextEditingController(text: '123-45-67890'),
      'company_name': TextEditingController(text: userData['company_name']),
      'address': TextEditingController(text: "${userData['addr1']} ${userData['addr2']} ${userData['addrDetail']}"),
      'bizType': TextEditingController(text: '도소매업'),
      'category': TextEditingController(text: '식품 소매업'),
    };
  }


  Widget _buildTextField(String label, String key, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        readOnly: readOnly,
        //keyboardType: TextInputType type,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black12,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3), // 둥글기 정도 조절
            borderSide: BorderSide.none, // 테두리 없음
          ),
        ),
      ),
    );
  }


Widget _buildBussinessForm() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField('사업자등록번호', 'bizNumber', readOnly: true),
          _buildTextField('상호(법인명)', 'company_name'),
          _buildTextField('사업장주소','address'),
          _buildTextField('업태','bizType', readOnly: true),
          _buildTextField('종목','category', readOnly: true)
          ]
      ),
    ),
  );
}


Widget _buildForm() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField('아이디', 'id', readOnly: true),
          _buildPasswordButton('비밀번호'),
          _buildTextField('이름', 'name', readOnly: true),
          _buildTextField('회사명', 'company'),
          _buildPostcodeField('주소','address'),
        ],
      ),
    ),
  );
}

Widget _buildPasswordButton(String label){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) =>  ChangePasswordPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: const Text('비밀번호 변경'),
        ),
      ),
    );
}


Widget _buildPostcodeField(String label,String key){
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Flexible(fit: FlexFit.tight, flex : 3, child: _buildTextField(label, key) ),
        SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: ActionButtonGroup(
              buttons: [ ActionButtonData(
                  label: '주소 검색',
                  backgroundColor: Colors.brown,
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DaumPostcodeView(
                            onComplete: (DaumPostcodeModel result) {
                              Navigator.of(context).pop({'address': result.address,});
                            }))
                    );
                    if (result != null) _controllers[key]!.text = result['address'];
                  })
              ]),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: const Text('정보 수정', style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body:
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForm(),
            _buildBussinessForm(),
            _buildWithdrawal(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton()
    );
  }


  Widget _buildWithdrawal(){
    return  Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WithdrawalPage()));
        },
        child: const Text('회원탈퇴', style: TextStyle(fontSize: 14, color: Colors.black, decoration: TextDecoration.underline)),
      ),
    );
  }

//회원가입 요청 함수
  Future<void> _register() async {
    if (!_validateForm()) return;

    try {
      final response = await _submitRegistration();
      if (!mounted) return;

      if (response.statusCode == 201) { //회원가입 성공
        _showMessage('수정 완료되었습니다!', isSuccess: true, onClose: () {} );
      } else { //실패처리
        _showMessage('수정에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) _showMessage('네트워크 오류가 발생했습니다.');
    }
  }

  bool _validateForm() {
    if (_controllers['address'] == null) {
      _showMessage('주소를 입력하세요.');
      return false;
    }

    if (_controllers['company_name'] == null) {
      _showMessage('회사명을 입력하세요.');
      return false;
    }
    return true;
  }

//서버에 회원가입 요청 보내기
  Future<http.Response> _submitRegistration() async {
    final address = (_controllers['address']!.text.trim()).split(RegExp(r'\s+'));

    final body = <String, String>{
      'password': _controllers['password']!.text,
      'password2': _controllers['password2']!.text,
      'company_name': _controllers['company']!.text,
      'addr1': address.length > 0 ? address[0] : '',
      'addr2': address.length > 1 ? address[1] : '',
      'addrDetail': address.length > 2 ? address.sublist(2).join(' ') : '',
    };

    return await http.post(
      Uri.parse('$BASE_URL/auth/api-register'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );
  }


//팝업 메시지 표시
  void _showMessage(String message, {bool isSuccess = false, VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(isSuccess ? '성공' : '오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onClose != null) onClose();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          child: const Text('수정완료', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
