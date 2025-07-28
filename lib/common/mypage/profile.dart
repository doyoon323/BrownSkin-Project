import 'package:brownskin_app/common/mypage/set_password.dart';
import 'package:brownskin_app/common/mypage/withdraw.dart';
import 'package:daum_postcode_view/daum_postcode_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../widgets.dart';

class EditProfilePage extends StatefulWidget {
  final String token;
  final Map<String,dynamic> Info;
  EditProfilePage({super.key, required this.Info, required this.token});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Map<String, TextEditingController> _controllers = {};
  Map<String,dynamic> userData = {};


  @override void initState() {
    super.initState();
    _initController();
  }


  Future<Map<String, dynamic>> getProfile() async {
    return widget.Info;
  }


  void _initController() async {
    final fetched = await getProfile();
    setState(() {
      userData = fetched;
      _controllers = {
        'id': TextEditingController(text: fetched['username'] ?? ''),
        'name': TextEditingController(text: fetched['name'] ?? ''),
        'phone': TextEditingController(text: fetched['phone'] ?? ''),
        'bizNumber': TextEditingController(text: fetched['bizNumber'] ?? '123-4515-1561'),
        'company_name': TextEditingController(text: fetched['company_name'] ?? ''),
        'address': TextEditingController(text: "${fetched['addr1'] ?? ''} ${fetched['addr2'] ?? ''} ${fetched['addrDetail'] ?? ''}"),
        'bizType': TextEditingController(text: fetched['bizType'] ?? '도소매업'),
        'category': TextEditingController(text: fetched['category'] ?? '식품 소매업'),
      };
    });
  }


  Widget _buildTextField(String label, String key,TextInputType type, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controllers[key],
            readOnly: readOnly,
            keyboardType:  type,
            decoration: InputDecoration(
                hintText: _controllers[key]?.text ?? '',
                filled: true,
                fillColor: Colors.black12,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide.none)
        ),
      ),
    ])
    );
  }



Widget _buildBussinessForm() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      child: Column(
        children: [
          _buildTextField('사업자등록번호', 'bizNumber',TextInputType.text, readOnly: true),
          _buildTextField('상호(법인명)', 'company_name',TextInputType.text, readOnly: true),
          _buildTextField('사업장주소','address',TextInputType.text, readOnly: true),
          _buildTextField('업태','bizType', TextInputType.text,readOnly: true),
          _buildTextField('종목','category', TextInputType.text, readOnly: true)
          ]
      ),
    ),
  );
}


Widget _buildForm() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      child: Column(
        children: [
          _buildTextField('아이디', 'id', TextInputType.text,readOnly: true),
          _buildPasswordButton('비밀번호'),
          _buildTextField('이름', 'name', TextInputType.text,readOnly: true),
          _buildTextField('회사명', 'company_name',TextInputType.text,),
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
        Flexible(fit: FlexFit.tight, flex : 3, child: _buildTextField(label, key,TextInputType.text) ),
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

      if (response.statusCode == 200) {
        _showMessage('수정이 완료되었습니다.', isSuccess: true, onClose: () {
          Navigator.pop(context,true);
        });
      } else {
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

  Future<http.Response> _submitRegistration() async {
    final address = (_controllers['address']!.text.trim()).split(RegExp(r'\s+'));

    final body = <String, String>{
      'company_name': _controllers['company_name']!.text,
      'addr1': address.length > 0 ? address[0] : '',
      'addr2': address.length > 1 ? address[1] : '',
      'addrDetail': address.length > 2 ? address.sublist(2).join(' ') : '',
    };

    final url = Uri.parse('$BASE_URL/auth/api-profile-update');

    final response = await http.patch(
      url,
      headers: {'Authorization': 'Token ${widget.token}'},
      body: body,
    );
    return response;
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
