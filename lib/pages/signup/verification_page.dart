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

  String parsedtext = '';
  String parsedBIN = ''; // 추출된 사업자등록번호
  final TextEditingController _binController = TextEditingController(); // 사업자등록번호 수정용 컨트롤러

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
          // 사업자등록번호 섹션
          if (true) ...[ // BIN 없을 때 표시 없애려면 조건 추가
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrown,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '추출된 사업자번호',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.accentBrown.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.backgroundBrown.withOpacity(0.1),
              ),
              child: TextField(
                controller: _binController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBrown,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: '000-00-00000',
                  hintStyle: TextStyle(
                    color: AppColors.lightBrown,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: Icon(
                    Icons.edit,
                    color: AppColors.primaryBrown.withOpacity(0.6),
                    size: 18,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    parsedBIN = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: AppColors.accentBrown.withOpacity(0.3),
              thickness: 1,
            ),
            const SizedBox(height: 20),
          ],
          // OCR 원본 텍스트 섹션
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.lightBrown,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'OCR 원본 텍스트',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

    // 사업자등록번호 추출
    await extractBusinessNumber(parsedtext);
  }

  // LLM API를 통해 사업자등록번호 추출하는 함수
  Future<void> extractBusinessNumber(String parsedText) async {
    if (parsedText.isEmpty) {
      debugPrint("ParsedText is empty, cannot extract business number");
      return;
    }

    debugPrint("Extracting business number from: $parsedText");

    var url = 'https://api.groq.com/openai/v1/chat/completions';
    var payload = {
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages": [
        {
          "role": "system",
          "content": "당신은 한국의 사업자등록증에서 사업자등록번호만 정확히 추출하는 전문가입니다. 사업자등록번호는 XXX-XX-XXXXX 형식의 10자리 숫자입니다. 다른 정보는 무시하고 사업자등록번호만 반환하세요."
        },
        {
          "role": "user",
          "content": "다음 텍스트는 문자인식(OCR)을 통해 추출한 사업자등록증 이미지의 결과입니다. 일부 글자가 깨져 있거나, 숫자 대신 알파벳이나 한자가 들어갔을 수 있습니다.당신의 임무는 다음과 같습니다:1. 텍스트에서 사업자등록번호를 하나 추출하세요.2. 형식은 반드시 `000-00-00000` (숫자만, 하이픈 포함) 형식이어야 합니다.3. 만약 숫자처럼 보이는 알파벳이나 한자가 있다면 자동으로 숫자로 정정하세요.- 예: `I` → `1`, `O` → `0`, `S` → `5`, `B` → `8` 등4. 알파벳이나 한자가 포함된 번호는 절대 그대로 출력하지 마세요.5. 가장 먼저 등장하는 사업자등록번호 하나만 출력하세요.6. 출력은 번호 하나만, 아무 설명 없이 출력하세요. (예: `123-45-67890`)다음은 OCR 결과입니다:$parsedText"
        }
      ],
    };

    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer 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"
    };

    try {
      var post = await http.post(
        Uri.parse(url),
        body: jsonEncode(payload),
        headers: header
      );

      var result = jsonDecode(post.body);
      debugPrint("LLM Result: $result");

      String extractedBIN = result['choices'][0]['message']['content'].trim();

      if (extractedBIN.isEmpty || !RegExp(r'^\d{3}-\d{2}-\d{5}$').hasMatch(extractedBIN)) {
        debugPrint("Invalid business number format: $extractedBIN");
        extractedBIN = "인식 실패. 직접 입력해주세요.";
      }

      setState(() {
        parsedBIN = extractedBIN;
        _binController.text = extractedBIN; // 텍스트박스에 자동으로 표시
      });

      debugPrint("Extracted Business Number: $parsedBIN");
    } catch (e) {
      debugPrint("Error extracting business number: $e");
    }
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
