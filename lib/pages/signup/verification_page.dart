import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_form_page.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/common/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';


class VerificationPage extends StatefulWidget {
  final String selectedRole;
  const VerificationPage({super.key, required this.selectedRole});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  String? _selectedType;
  bool _documentUploaded = false;
  File? _imageFile;

  final Map<String, List<Map<String, String>>> typeOptions = {
    'transporter': [
      {'value': 'clean', 'label': '클린 운송', 'desc': '위생 운송 서비스'},
      {'value': 'normal', 'label': '일반 운송', 'desc': '표준 운송 서비스'},
    ],
    'preprocessor': [
      {'value': 'A', 'label': 'A라인', 'desc': 'A라인 농부산물 전처리'},
      {'value': 'B', 'label': 'B라인', 'desc': 'B라인 농부산물 전처리'},
      {'value': 'C', 'label': 'C라인', 'desc': 'C라인 농부산물 전처리'},
      {'value': 'D', 'label': 'D라인', 'desc': 'D라인 농부산물 전처리'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final requiresType = typeOptions.containsKey(widget.selectedRole);
    final availableTypes = typeOptions[widget.selectedRole] ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundBrown,
      appBar: buildCustomAppBar(
        context: context,
        title: '사업자 인증',
        showBackButton: true,
        showActions: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundBrown,
              AppColors.backgroundBrown,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildDocumentUploadSection(),
                  _buildParsedTextSection(),
                  const SizedBox(height: 32),
                  if (requiresType) ...[
                    _buildTypeSelectionSection(availableTypes),
                    const SizedBox(height: 32),
                  ],
                  _buildCompleteButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.verified_user,
              size: 40,
              color: AppColors.primaryBrown,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '업체 확인을 위한\n사업자 등록증을 첨부해주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBrown,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '사업자 등록증 사진과 정보를 등록해주세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryBrown.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            //카메라 인식
            _imageFile = await pickImageFromCamera();


            //_imageFile = await pickImageFromGallery();
            await parsedTest(_imageFile!);
            //print("😚😚😚😚😙: $parsedtext");
            debugPrint("!!!\n!!!imageFile size: ${_imageFile?.lengthSync()}\n!!!");
            setState(() {
              _documentUploaded = !_documentUploaded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _documentUploaded
                        ? AppColors.primaryBrown.withAlpha(25)
                        : AppColors.accentBrown.withAlpha(76),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _documentUploaded ? Image.file(File(_imageFile!.path))
                      : Icon(Icons.upload_file,
                    size: 30,
                    color: _documentUploaded
                        ? AppColors.primaryBrown
                        : AppColors.lightBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParsedTextSection() {
    if (parsedtext.isEmpty) return SizedBox.shrink(); // 아무것도 없으면 비워두기

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parsedtext,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBrown,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectionSection(List<Map<String, String>> availableTypes) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '세부 유형 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...availableTypes.map((type) => _buildTypeOption(type)).toList(),
        ],
      ),
    );
  }

  Widget _buildTypeOption(Map<String, String> type) {
    final isSelected = _selectedType == type['value'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppColors.primaryBrown 
              : AppColors.accentBrown,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? AppColors.primaryBrown.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedType = type['value'];
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primaryBrown 
                          : AppColors.lightBrown,
                      width: 2,
                    ),
                    color: isSelected 
                        ? AppColors.primaryBrown 
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type['label']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? AppColors.primaryBrown 
                              : AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['desc']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    final canProceed = !typeOptions.containsKey(widget.selectedRole) || 
                      _selectedType != null;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: canProceed
            ? LinearGradient(
                colors: [AppColors.primaryBrown, AppColors.darkBrown],
              )
            : null,
        color: canProceed ? null : AppColors.lightBrown,
        boxShadow: canProceed
            ? [
                BoxShadow(
                  color: AppColors.primaryBrown,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canProceed
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignUpFormPage(
                        selectedRole: widget.selectedRole,
                        selectedType: _selectedType,
                      ),
                    ),
                  );
                }
              : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  color: canProceed ? Colors.white : AppColors.lightBrown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '인증 완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canProceed ? Colors.white : AppColors.lightBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// 에뮬레이터에서는 동작하나, 실제 배포하여 테스트했을 때 돌아가지 않음

  //카메라로 사진찍는 코드
  Future<File?> pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }




  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }


  String parsedtext = '';


  Future<void> parsedTest(File pickedFile) async {
    File processedFile = pickedFile;

    // 파일 크기 확인 (1024KB = 1048576 bytes)
    int fileSizeInBytes = pickedFile.lengthSync();
    debugPrint("Original file size: ${fileSizeInBytes / 1024} KB");

    if (fileSizeInBytes > 1048576) { // 1024KB 초과시 압축
      debugPrint("File size exceeds 1024KB, compressing...");
      processedFile = await compressImage(pickedFile);
      debugPrint("Compressed file size: ${processedFile.lengthSync() / 1024} KB");
    }

    var bytes = processedFile.readAsBytesSync();
    String img64 = base64Encode(bytes);

    var url = 'https://api.ocr.space/parse/image';
    var payload = {"base64Image": "data:image/jpg;base64,${img64.toString()}","language" :"kor"};
    var header = {"apikey" :"K81055865188957"};

    var post = await http.post(Uri.parse(url),body: payload,headers: header);
    var result = jsonDecode(post.body);

    setState(() {
      parsedtext = result['ParsedResults'][0]['ParsedText'];
    });
  }

  // 이미지 압축 함수
  Future<File> compressImage(File file) async {
    // 원본 이미지 읽기
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('이미지를 읽을 수 없습니다.');
    }

    // 이미지 크기 조정 (긴 쪽을 기준으로 최대 1920px로 제한)
    img.Image resizedImage;
    if (image.width > image.height) {
      // 가로가 더 긴 경우
      resizedImage = img.copyResize(image, width: 1920);
    } else {
      // 세로가 더 긴 경우
      resizedImage = img.copyResize(image, height: 1920);
    }

    // JPEG로 인코딩 (품질 85%)
    final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

    // 압축된 파일을 임시 파일로 저장
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }
}
