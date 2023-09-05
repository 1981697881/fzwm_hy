import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_hy/model/currency_entity.dart';
import 'package:fzwm_hy/model/submit_entity.dart';
import 'package:fzwm_hy/utils/handler_order.dart';
import 'package:fzwm_hy/utils/refresh_widget.dart';
import 'package:fzwm_hy/utils/text.dart';
import 'package:fzwm_hy/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwm_hy/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseAffirmDetail extends StatefulWidget {
  var FBillNo;

  PurchaseAffirmDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _PurchaseAffirmDetailState createState() =>
      _PurchaseAffirmDetailState(FBillNo);
}

class _PurchaseAffirmDetailState extends State<PurchaseAffirmDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();

  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var supplierName;
  var supplierNumber;
  var departmentName;
  var departmentNumber;
  var typeName;
  var typeNumber;
  var show = false;
  var isSubmit = false;
  var isScanWork = false;
  var checkData;
  var checkDataChild;
  var stockName;
  var stockNumber;
  var selectData = {
    DateMode.YMD: "",
  };
  var departmentList = [];
  List<dynamic> departmentListObj = [];
  var supplierList = [];
  List<dynamic> supplierListObj = [];
  var stockList = [];
  var typeList = [];
  List<dynamic> typeListObj = [];
  List<dynamic> stockListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  List<dynamic> collarOrderDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var fBillNo;
  var fOrgID;
  var fBarCodeList;

  _PurchaseAffirmDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      getSupplierList();
      getDepartmentList();
      this.fBillNo = '';
      getStockList();
    }
  }

  @override
  void initState() {
    super.initState();
    DateTime dateTime = DateTime.now();
    var nowDate = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    selectData[DateMode.YMD] = nowDate;

    /// 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
    EasyLoading.dismiss();
  }

  //获取部门
  getDepartmentList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    userMap['FormId'] = 'BD_Department';
    userMap['FieldKeys'] = 'FUseOrgId,FName,FNumber';
    userMap['FilterString'] = "FUseOrgId.FNumber ='" + deptData[1] + "'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    departmentListObj = jsonDecode(res);
    departmentListObj.forEach((element) {
      departmentList.add(element[1]);
    });
  }

  //获取线路名称
  getTypeList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BOS_ASSISTANTDATA_DETAIL';
    userMap['FieldKeys'] = 'FId,FDataValue,FNumber';
    userMap['FilterString'] = "FId ='5fd715f4883532' and FForbidStatus='A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    typeListObj = jsonDecode(res);
    typeListObj.forEach((element) {
      typeList.add(element[1]);
    });
  }

  //获取供应商
  getSupplierList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Supplier';
    userMap['FieldKeys'] = 'FSupplierId,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    supplierListObj = jsonDecode(res);
    supplierListObj.forEach((element) {
      supplierList.add(element[1]);
    });
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation,FFlexNumber';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FUseOrgId.FNumber =" + fOrgID;
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  void getWorkShop() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.getString('FWorkShopName') != null) {
        FName = sharedPreferences.getString('FWorkShopName');
        FNumber = sharedPreferences.getString('FWorkShopNumber');
        isScanWork = true;
      } else {
        isScanWork = false;
      }
    });
  }

  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];

  getOrderList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] = "FBillNo='$fBillNo'";
    userMap['FormId'] = 'STK_InStock';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
    'FStockId.FNumber,FStockId.FName,FStockOrgId.FNumber';
    Map<String, dynamic> stockMap = Map();
    stockMap['data'] = userMap;
    String stockRes = await CurrencyEntity.polling(stockMap);
    var stockFlex = jsonDecode(stockRes);
    String order = "";
    if(stockFlex.length>0){
      Map<String, dynamic> stockMap = Map();
      stockMap['FormId'] = 'BD_STOCK';
      stockMap['FieldKeys'] =
      'FStockID,FName,FNumber,FIsOpenLocation,FFlexNumber';
      stockMap['FilterString'] = "FNumber = '" +
          stockFlex[0][0] +
          "' and FUseOrgId.FNumber = '" +
          stockFlex[0][2] +
          "'";
      Map<String, dynamic> stockDataMap = Map();
      stockDataMap['data'] = stockMap;
      String res = await CurrencyEntity.polling(stockDataMap);
      var stockRes = jsonDecode(res);
      if (stockRes.length > 0) {
        userMap['FieldKeys'] =
        'FBillNo,FSupplierId.FNumber,FSupplierId.FName,FDate,FInStockEntry_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FStockOrgId.FNumber,FStockOrgId.FName,FBaseUnitID.FNumber,FBaseUnitID.FName,FMustQty,FSrcBillNo,FID,FMaterialId.FIsBatchManage,FStockId.FNumber,FStockId.FName,FUnitID.FNumber,FRealQty,FOwnerIdHead.FNumber,FDocumentStatus,FProduceDate,FExpiryDate,FMaterialId.FIsKFPeriod,FStockID.FIsOpenLocation,FStockLocId.'+stockRes[0][4] +'.FName,FLot.FNumber';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = userMap;
        order = await CurrencyEntity.polling(dataMap);
        orderDate = [];
        orderDate = jsonDecode(order);
        FDate = formatDate(DateTime.now(), [
          yyyy,
          "-",
          mm,
          "-",
          dd,
        ]);
        selectData[DateMode.YMD] = formatDate(DateTime.now(), [
          yyyy,
          "-",
          mm,
          "-",
          dd,
        ]);
        hobby = [];
        if (orderDate.length > 0) {
          this.fOrgID = orderDate[0][8];
          for (var value in orderDate) {
            fNumber.add(value[5]);
            List arr = [];
            arr.add({
              "title": "物料名称",
              "name": "FMaterial",
              "isHide": false,
              "value": {
                "label": value[6] + "- (" + value[5] + ")",
                "value": value[5],
                "barcode": [],
                "kingDeeCode": [],
                "scanCode": []
              }
            });
            arr.add({
              "title": "规格型号",
              "isHide": false,
              "name": "FMaterialIdFSpecification",
              "value": {"label": value[7], "value": value[7]}
            });
            arr.add({
              "title": "单位名称",
              "name": "FUnitId",
              "isHide": false,
              "value": {"label": value[11], "value": value[10]}
            });
            arr.add({
              "title": "实收数量",
              "name": "FRealQty",
              "isHide": false,
              /*value[12]*/
              "value": {"label": "0", "value": "0"}
            });
            arr.add({
              "title": "仓库",
              "name": "FStockID",
              "isHide": false,
              "value": {"label": value[17], "value": value[16]}
            });
            arr.add({
              "title": "批号",
              "name": "FLot",
              "isHide": value[15] != true,
              "value": {"label": value[27], "value": value[27]}
            });
            if (value[26]!= null) {
              arr.add({
                "title": "仓位",
                "name": "FStockLocID",
                "isHide": false,
                "value": {
                  "label": value[26],
                  "value": value[26],
                  "hide": true,
                  'dimension': stockRes[0][4]
                }
              });
            } else {
              arr.add({
                "title": "仓位",
                "name": "FStockLocID",
                "isHide": false,
                "value": {"label": "", "value": "", "hide": false, 'dimension': ""}
              });
            }
            arr.add({
              "title": "操作",
              "name": "",
              "isHide": false,
              "value": {"label": "", "value": ""}
            });
            arr.add({
              "title": "库存单位",
              "name": "",
              "isHide": true,
              "value": {"label": value[18], "value": value[18]}
            });
            Map<String, dynamic> barcodeMap = Map();
            barcodeMap['FilterString'] = "FMATERIALID.FNUMBER='" +
                value[5] +
                "'and FSrcBillNo='" +
                fBillNo +
                "'and FBatchNo='" +
                value[27] +
                "' and FStock='" +
                value[16] +
                "/" +
                value[17] +
                "'";
            barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
            barcodeMap['FieldKeys'] =
            'FID,FInQtyTotal,FOutQtyTotal,FRemainQty,FBarCodeQty,FStock,FLoc,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FStockOrgID.FNumber,FBarCodeEn';
            Map<String, dynamic> barcodeDataMap = Map();
            barcodeDataMap['data'] = barcodeMap;
            String order = await CurrencyEntity.polling(barcodeDataMap);
            var barcodeData = jsonDecode(order);
            if (barcodeData.length > 0) {}
            arr.add({
              "title": "应收数量",
              "name": "FQty",
              "isHide": false,
              "value": {
                "label": value[12].toString() +
                    "-包数(" +
                    barcodeData.length.toString() +
                    ")",
                "value": value[12],
                "rateValue": value[12]
              } /*+value[12]*0.1*/
            });
            arr.add({
              "title": "最后扫描数量",
              "name": "FLastQty",
              "isHide": false,
              "value": {"label": "0", "value": "0"}
            });
            arr.add({
              "title": "生产日期",
              "name": "FProduceDate",
              "isHide": value[24] != true,
              "value": {
                "label": value[22] == null ? '' : value[22].substring(0, 10),
                "value": value[22] == null ? '' : value[22].substring(0, 10)
              }
            });
            arr.add({
              "title": "有效期至",
              "name": "FExpiryDate",
              "isHide": value[24] != true,
              "value": {
                "label": value[23] == null ? '' : value[23].substring(0, 10),
                "value": value[23] == null ? '' : value[23].substring(0, 10)
              }
            });
            hobby.add(arr);
          }
          ;
          setState(() {
            EasyLoading.dismiss();
            this._getHobby2();
          });
        } else {
          setState(() {
            EasyLoading.dismiss();
            this._getHobby2();
          });
          ToastUtil.showInfo('无数据');
        }
      }
    }
    getStockList();
  }

  void _onEvent(event) async {
    if (checkItem == 'FStockLocID') {
      _FNumber = event.trim();
      this._textNumber.value = _textNumber.value.copyWith(
        text: event.trim(),
      );
    } else {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var deptData = sharedPreferences.getString('menuList');
      var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
      fBarCodeList = menuList['FBarCodeList'];
      if (event == "") {
        return;
      }
      if (fBarCodeList == 1) {
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCodeEn='" + event.trim() + "'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['FieldKeys'] =
        'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStock,FLoc,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FBatchNo';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          var msg = "";
          var orderIndex = 0;
          print(fNumber);
          for (var value in orderDate) {
            print(value[7]);
            print(barcodeData[0][8]);
            if (value[5] == barcodeData[0][8]) {
              msg = "";
              if (fNumber.lastIndexOf(barcodeData[0][8]) == orderIndex) {
                break;
              }
            } else {
              msg = '条码不在单据物料中';
            }
            orderIndex++;
          }
          ;
          if (msg == "") {
            _code = event;
            this.getMaterialList(
                barcodeData,
                barcodeData[0][10],
                barcodeData[0][11],
                barcodeData[0][12],
                barcodeData[0][13],
                barcodeData[0][14],
                barcodeData[0][7]);
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('条码不在条码清单中');
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, '', '', '', '', '');
        print("ChannelPage: $event");
      }
    }
    checkItem = '';
    print("ChannelPage: $event");
  }

  getMaterialList(
      barcodeData, code, fsn, fProduceDate, fExpiryDate, fBatchNo, fLoc) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = code.split(";");
    userMap['FilterString'] = "FNumber='" +
        barcodeData[0][8] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = '" +
        deptData[1] +
        "'";
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage'; /*,SubHeadEntity1.FStoreUnitID.FNumber*/
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (materialDate.length > 0) {
      var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      } else {
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[4];
      var residue = double.parse(scanCode[4]);
      var hobbyIndex = 0;
      var errorTitle = "";
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              /*if(element[6]['value']['hide']){
                if(element[6]['value']['label'] == fLoc){
                  errorTitle = "";
                }else{
                  errorTitle = "仓位不一致";
                  continue;
                }
              }*/

              if (scanCode[5] == "N") {
                /*&& double.parse(barcodeNum) > (element[9]['value']['label'] - (double.parse(element[3]['value']['label'])))  ToastUtil.showInfo('条码为不可切分条码且数量大于应收/应发数量');*/
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                break;
              }
              //判断条码数量
              if ((double.parse(element[3]['value']['label']) +
                          double.parse(barcodeNum)) >
                      0 &&
                  double.parse(barcodeNum) > 0) {
                //判断物料是否重复 首个下标是否对应末尾下标
                if (fNumber.indexOf(element[0]['value']['value']) ==
                    fNumber.lastIndexOf(element[0]['value']['value'])) {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    element[3]['value']['label'] =
                        (double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum))
                            .toString();
                    element[3]['value']['value'] = element[3]['value']['label'];
                    var item = barCodeScan[0].toString() + "-" + barcodeNum;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                    print(2);
                    print(element[0]['value']['kingDeeCode']);
                  }
                } else {
                  //判断扫描数量是否大于单据数量
                  if (double.parse(element[3]['value']['label']) >=
                      element[9]['value']['label']) {
                    continue;
                  } else {
                    //判断二维码数量是否大于单据数量
                    if ((double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum)) >=
                        element[9]['value']['label']) {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        var item = barCodeScan[0].toString() +
                            "-" +
                            (element[9]['value']['label'] -
                                    double.parse(element[3]['value']['label']))
                                .toString();
                        element[10]['value']['label'] = (element[9]['value']
                                    ['label'] -
                                double.parse(element[3]['value']['label']))
                            .toString();
                        element[10]['value']['value'] = (element[9]['value']
                                    ['label'] -
                                double.parse(element[3]['value']['label']))
                            .toString();
                        barcodeNum = (double.parse(barcodeNum) -
                                (element[9]['value']['label'] -
                                    double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['label'] = (double.parse(
                                    element[3]['value']['label']) +
                                (element[9]['value']['label'] -
                                    double.parse(element[3]['value']['label'])))
                            .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        residue = element[9]['value']['label'] -
                            double.parse(element[3]['value']['label']);
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        print(1);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {
                      //数量不超出
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['label']) +
                                    double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    }
                  }
                }
              }
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        } else {
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              /*if(element[6]['value']['hide']){
                if(element[6]['value']['label'] == fLoc){
                  errorTitle = "";
                }else{
                  errorTitle = "仓位不一致";
                  continue;
                }
              }*/

              //启用批号
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = fBatchNo;
                    element[5]['value']['value'] = fBatchNo;
                  }
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                break;
              }
              if (element[5]['value']['value'] == fBatchNo) {
                //判断条码数量
                if ((double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum)) >
                        0 &&
                    double.parse(barcodeNum) > 0) {
                  //判断物料是否重复 首个下标是否对应末尾下标
                  if (fNumber.indexOf(element[0]['value']['value']) ==
                      fNumber.lastIndexOf(element[0]['value']['value'])) {
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['label']) +
                                  double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  } else {
                    //判断扫描数量是否大于单据数量
                    if (double.parse(element[3]['value']['label']) >=
                        element[9]['value']['label']) {
                      continue;
                    } else {
                      //判断二维码数量是否大于单据数量
                      if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >=
                          element[9]['value']['label']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[9]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                  .toString();
                          element[10]['value']['label'] = (element[9]['value']
                                      ['label'] -
                                  double.parse(element[3]['value']['label']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                                      ['label'] -
                                  double.parse(element[3]['value']['label']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                                  (element[9]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      (element[9]['value']['label'] -
                                          double.parse(
                                              element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          residue = element[9]['value']['label'] -
                              double.parse(element[3]['value']['label']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          print(1);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      } else {
                        //数量不超出
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          var item =
                              barCodeScan[0].toString() + "-" + barcodeNum;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                                  double.parse(barcodeNum))
                              .toString();
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    }
                  }
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = fBatchNo;
                  element[5]['value']['value'] = fBatchNo;
                  //判断条码数量
                  if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >
                          0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断物料是否重复 首个下标是否对应末尾下标
                    if (fNumber.indexOf(element[0]['value']['value']) ==
                        fNumber.lastIndexOf(element[0]['value']['value'])) {
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['label']) +
                                    double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {
                      //判断扫描数量是否大于单据数量
                      if (double.parse(element[3]['value']['label']) >=
                          element[9]['value']['label']) {
                        continue;
                      } else {
                        //判断二维码数量是否大于单据数量
                        if ((double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum)) >=
                            element[9]['value']['label']) {
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            var item = barCodeScan[0].toString() +
                                "-" +
                                (element[9]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label']))
                                    .toString();
                            element[10]['value']['label'] = (element[9]['value']
                                        ['label'] -
                                    double.parse(element[3]['value']['label']))
                                .toString();
                            element[10]['value']['value'] = (element[9]['value']
                                        ['label'] -
                                    double.parse(element[3]['value']['label']))
                                .toString();
                            barcodeNum = (double.parse(barcodeNum) -
                                    (element[9]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label'])))
                                .toString();
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['label']) +
                                        (element[9]['value']['label'] -
                                            double.parse(
                                                element[3]['value']['label'])))
                                    .toString();
                            element[3]['value']['value'] =
                                element[3]['value']['label'];
                            residue = element[9]['value']['label'] -
                                double.parse(element[3]['value']['label']);
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            print(1);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        } else {
                          //数量不超出
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['label']) +
                                        double.parse(barcodeNum))
                                    .toString();
                            element[3]['value']['value'] =
                                element[3]['value']['label'];
                            var item =
                                barCodeScan[0].toString() + "-" + barcodeNum;
                            element[10]['value']['label'] =
                                barcodeNum.toString();
                            element[10]['value']['value'] =
                                barcodeNum.toString();
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            barcodeNum = (double.parse(barcodeNum) -
                                    double.parse(barcodeNum))
                                .toString();
                            print(2);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        }
                      }
                    }
                  }
                  //判断是否可重复扫码
                  if (scanCode.length > 4) {
                    element[0]['value']['barcode'].add(code);
                  }
                } else {
                  errorTitle = "批号不一致";
                  continue;
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      if (errorTitle != "") {
        ToastUtil.errorDialog(context, errorTitle);
      }
      print(hobbyIndex);
      print(residue);
      setState(() {
        EasyLoading.dismiss();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
      });
      ToastUtil.showInfo('无数据');
    }
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  Widget _item(title, var data, selectData, hobby, {String? label, var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(title),
                      onTap: () => data.length > 0
                          ? _onClickItem(data, selectData, hobby,
                          label: label, stock: stock)
                          : {ToastUtil.showInfo('无数据')},
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        MyText(selectData.toString() == "" ? '暂无' : selectData.toString(),
                            color: Colors.grey, rightpadding: 18),
                        rightIcon
                      ]),
                    ),
                  ),
                  divider,
                ],
              );
            });
  }

  Widget _dateItem(title, model) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18);
              }),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (FDate == '' || FDate == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(FDate))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          switch (model) {
            case DateMode.YMD:
              selectData[model] = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              FDate = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby,
      {String? label, var stock}) {

    Pickers.showSinglePicker(
      context,
      data: data,
      selectData: selectData,
      pickerStyle: DefaultPickerStyle(),
      suffix: label,
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        print('longer >>> 返回数据类型：${p.runtimeType}');
        setState(() {
          if (hobby == 'supplier') {
            supplierName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                supplierNumber = supplierListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'department') {
            departmentName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                departmentNumber = departmentListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else {
           /* this.stockName = p;
            selectData = p;

            for(var element in data){
              if (element == p) {
                this.stockNumber = stockListObj[elementIndex][2];
              }
              elementIndex++;
            }

            print(this.stockName);
            print(this.stockNumber);*/
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                hobby['value']['dimension'] = stockListObj[elementIndex][4];
                stock[6]['value']['hide'] = stockListObj[elementIndex][3];
                stock[6]['value']['label'] = "";
                stock[6]['value']['value'] = "";
              }
              elementIndex++;
            });
            Navigator.pop(context);
            this.checkItem = "";
          }
        });
      },
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 3 || j == 5) {
            /*|| j==5*/
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                this._textNumber.text = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                this._FNumber = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                checkItem = 'FNumber';
                                this.show = false;
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                print(this.hobby[i][j]["value"]["label"]);
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                    text: this
                                        .hobby[i][j]["value"]["label"]
                                        .toString(),
                                  );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else if (j == 4) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if (j == 6) {
            comList.add(
              Visibility(
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                visible: this.hobby[i][j]["value"]["hide"],
                child: Column(children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                        title: Text(this.hobby[i][j]["title"] +
                            '：' +
                            this.hobby[i][j]["value"]["label"].toString()),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: new Icon(Icons.filter_center_focus),
                                tooltip: '点击扫描',
                                onPressed: () {
                                  this._textNumber.text = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  this._FNumber = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  checkItem = 'FNumber';
                                  this.show = false;
                                  checkData = i;
                                  checkDataChild = j;
                                  scanDialog();
                                  print(this.hobby[i][j]["value"]["label"]);
                                  if (this.hobby[i][j]["value"]["label"] != 0) {
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: this
                                          .hobby[i][j]["value"]["label"]
                                          .toString(),
                                    );
                                  }
                                },
                              ),
                            ])),
                  ),
                  divider,
                ]),
              ),
            );
          } else if (j == 7) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new FlatButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
                              },
                            )
                          ])),
                ),
                divider,
              ]),
            );
          } else if (j == 10) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                this._textNumber.text = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                this._FNumber = this
                                    .hobby[i][j]["value"]["label"]
                                    .toString();
                                checkItem = 'FLastQty';
                                this.show = false;
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                print(this.hobby[i][j]["value"]["label"]);
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                    text: this
                                        .hobby[i][j]["value"]["label"]
                                        .toString(),
                                  );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString()),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                    ]),
                  ),
                ),
                divider,
              ]),
            );
          }
        }
      }
      tempList.add(
        SizedBox(height: 6, width: 320, child: ColoredBox(color: Colors.grey)),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }

  /*List<Widget> _getHobby2() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<DataColumn> dataColumnList = [];
      List<DataRow> dataRowList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (j == 0) {
          dataColumnList.add(DataColumn(
              tooltip: this.hobby[i][j]["value"]["label"],
              label: Container(
                width: 100,
                child: Text(
                  this.hobby[i][j]["value"]["label"],
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              )));
          dataColumnList.add(DataColumn(
              tooltip: this.hobby[i][j]["value"]["label"],
              label: Container(
                width: 100,
                child: Text(
                  this.hobby[i][j]["value"]["value"],
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              )));
        } else {
          List<DataCell> dataCellList = [];
          var dataCellIndex = this.hobby[i].length;
          for (var t = 0; t < dataCellIndex; t++) {
            if (!this.hobby[i][j]['isHide']) {
              if(dataCellList.length >1){
                break;
              }else if(j+1==dataCellIndex){
                dataCellList.add(DataCell(
                    Container(
                      width: 100,
                      child: Text(
                        "",
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                ));
              }else{
                if(j == 3 || j == 5 || j == 4 || j == 6){
                  print(this.hobby[i][j+t]['title']);
                  dataCellList.add(DataCell(
                      Container(
                        width: 100,
                        child: Text(
                          this.hobby[i][j+t]["title"] +
                              '：' +
                              this.hobby[i][j+t]["value"]["label"].toString(),
                          softWrap: true,
                        ),
                      ),
                      showEditIcon: true,
                      onTap: () {
                        this._textNumber.text = this
                            .hobby[i][j+t-1]["value"]["label"]
                            .toString();
                        this._FNumber = this
                            .hobby[i][j+t-1]["value"]["label"]
                            .toString();
                        checkItem = this.hobby[i][j+t-1]["name"];
                        this.show = false;
                        checkData = i;
                        checkDataChild = j+t-1;
                        if(checkItem == "FStockID"){
                          this.stockName = this.hobby[checkData][checkDataChild]['value']['label'];
                          this.stockNumber = this.hobby[checkData][checkDataChild]['value']['value'];
                        }
                        scanDialog();
                        print(this.hobby[i][j]["value"]["label"]);
                        if (this.hobby[i][j+t-1]["value"]["label"] != 0) {
                          this._textNumber.value =
                              _textNumber.value.copyWith(
                                text: this
                                    .hobby[i][j+t-1]["value"]["label"]
                                    .toString(),
                              );
                        }
                      },
                      placeholder: true));
                }else if(j == 7){
                  print(this.hobby[i][j+t]['title']);
                  if(t == 0){
                    dataCellList.add(DataCell(
                        Container(
                            width: 100,
                            height: 60,
                            alignment: Alignment.center,
                            child: Column(
                                children: <Widget>[
                                  FlatButton(
                                    color: Colors.red,
                                    textColor: Colors.white,
                                    child: new Text('删除',style: TextStyle(fontSize: 10.0)),
                                    onPressed: () {
                                      this.hobby.removeAt(i);
                                      setState(() {});
                                    },
                                  ),
                                ]
                            )
                        ),
                        placeholder: true));
                  }else{
                    dataCellList.add(DataCell(
                        Container(
                          width: 100,
                          child: Text(
                            "",
                            softWrap: true,
                          ),
                        ),
                        placeholder: true));
                  }
                }else{
                  if (!this.hobby[i][j+t]['isHide']) {
                    print(this.hobby[i][j+t]['title']);
                    dataCellList.add(DataCell(
                        Container(
                          width: 100,
                          child: Text(
                            this.hobby[i][j+t]["title"] +
                                '：' +
                                this.hobby[i][j+t]["value"]["label"].toString(),
                            softWrap: true,
                          ),
                        ),
                        placeholder: true));
                  }
                }
                j=j+t;
              }
            }

          }
          dataRowList.add(
            DataRow(
              cells: dataCellList,
            ),
          );
        }
      }
      tempList.add(
        SizedBox(height: 6, width: 320, child: ColoredBox(color: Colors.grey)),
      );
      tempList.add(
        Row(children: [
          Container(
              width: 320,
              child: DataTable(
                // 行
                rows: dataRowList,
                // 列
                columns: dataColumnList,
              ))
        ]),
      );
    }
    return tempList;
  }*/
  List<Widget> _getHobby2() {
    List<Widget> tempList = [];
    List<DataColumn> dataColumnList = [];
    List<DataRow> dataRowList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<DataCell> dataCellList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (i == 0) {
          if (!this.hobby[i][j]['isHide']) {
            dataColumnList.add(DataColumn(
              // tooltip: this.hobby[i][j]["value"]["label"],
                label: Text(
                  this.hobby[i][j]["title"],
                  style: TextStyle(fontSize: 12,color: Colors.blue),
                  softWrap: true,
                )));
          }
        }
        if (!this.hobby[i][j]['isHide']) {
          if(j == 3 || j == 5 || j == 4 || j == 6){
            dataCellList.add(DataCell(
                Container(
                  width: 100,
                  child: Text(
                    this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString(),
                    style: TextStyle(fontSize: 12.0),
                    softWrap: true,
                  ),
                ),
                showEditIcon: true,
                onTap: () {
                  this._textNumber.text = this
                      .hobby[i][j]["value"]["label"]
                      .toString();
                  this._FNumber = this
                      .hobby[i][j]["value"]["label"]
                      .toString();
                  checkItem = this.hobby[i][j]["name"];
                  this.show = false;
                  checkData = i;
                  checkDataChild = j;
                  if(checkItem == "FStockID"){
                    this.stockName = this.hobby[checkData][checkDataChild]['value']['label'];
                    this.stockNumber = this.hobby[checkData][checkDataChild]['value']['value'];
                  }
                  scanDialog();
                  if (this.hobby[i][j]["value"]["label"] != 0) {
                    this._textNumber.value =
                        _textNumber.value.copyWith(
                          text: this
                              .hobby[i][j]["value"]["label"]
                              .toString(),
                        );
                  }
                },
                placeholder: true));
          }else if(j == 7) {
            dataCellList.add(DataCell(
                Container(
                    width: 100,
                    height: 60,
                    alignment: Alignment.center,
                    child: Column(
                        children: <Widget>[
                          FlatButton(
                            color: Colors.red,
                            textColor: Colors.white,
                            child: new Text('删除',style: TextStyle(fontSize: 10.0)),
                            onPressed: () {
                              this.hobby.removeAt(i);
                              setState(() {});
                            },
                          ),
                        ]
                    )
                ),
                placeholder: true));
          }else{
            dataCellList.add(DataCell(
              Text(this.hobby[i][j]["value"]["label"].toString(),
                  style: TextStyle(fontSize: 12.0)),
            ));
          }
        }
      }
      dataRowList.add(
        DataRow(
          cells: dataCellList,
        ),
      );
    }
    /*tempList.add(
      SizedBox(height: 6, child: ColoredBox(color: Colors.grey)),
    );*/
    tempList.add(DataTable(
      // 行
      headingRowHeight: 40,
      rows: dataRowList,
      // 列
      columns: dataColumnList,
    ));
    return tempList;
  }
  //调出弹窗 扫码
  void scanDialog() {
    showDialog<Widget>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  /*  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('输入数量',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),*/
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: this.checkItem != "FStockID",
                    child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Card(
                            child: Column(children: <Widget>[
                              TextField(
                                style: TextStyle(color: Colors.black87),
                                keyboardType: TextInputType.number,
                                controller: this._textNumber,
                                decoration: InputDecoration(hintText: "输入"),
                                onChanged: (value) {
                                  setState(() {
                                    this._FNumber = value;
                                  });
                                },
                              ),
                            ]))),
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: this.checkItem == "FStockID",
                    child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Card(
                            child: Column(children: <Widget>[
                              _item('', stockList, this.hobby[checkData][checkDataChild]['value']['label'],
                                  this.hobby[checkData][checkDataChild],
                                  stock: this.hobby[checkData]),
                            ]))),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          setState(() {
                            if (checkItem == "FLastQty") {
                              if (this
                                      .hobby[checkData][0]['value']
                                          ['kingDeeCode']
                                      .length >
                                  0) {
                                var kingDeeCode = this
                                    .hobby[checkData][0]['value']['kingDeeCode']
                                        [this
                                                .hobby[checkData][0]['value']
                                                    ['kingDeeCode']
                                                .length -
                                            1]
                                    .split("-");
                                var realQty = 0.0;
                                this
                                    .hobby[checkData][0]['value']['kingDeeCode']
                                    .forEach((item) {
                                  var qty = item.split("-")[1];
                                  realQty += double.parse(qty);
                                });
                                realQty = realQty -
                                    double.parse(this.hobby[checkData][10]
                                        ["value"]["label"]);
                                realQty = realQty + double.parse(_FNumber);
                                if (realQty >
                                    this.hobby[checkData][9]["value"]
                                        ["label"]) {
                                  ToastUtil.showInfo('总数量大于应收数量');
                                } else {
                                  this.hobby[checkData][3]["value"]["value"] =
                                      realQty.toString();
                                  this.hobby[checkData][3]["value"]["label"] =
                                      realQty.toString();
                                  this.hobby[checkData][checkDataChild]["value"]
                                      ["label"] = _FNumber;
                                  this.hobby[checkData][checkDataChild]['value']
                                      ["value"] = _FNumber;
                                  this.hobby[checkData][0]['value']
                                      ['kingDeeCode'][this
                                          .hobby[checkData][0]['value']
                                              ['kingDeeCode']
                                          .length -
                                      1] = kingDeeCode[0] + "-" + _FNumber;
                                }
                              } else {
                                ToastUtil.showInfo('无条码信息，输入失败');
                              }
                            }else{
                              setState(() {
                                this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                                this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                              });
                            }
                            this.checkItem = "";
                          });
                        },
                        child: Text(
                          '确定',
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).then((val) {
      print(val);
    });
  }

  /// 确认提交提示对话框
  Future<void> _showSumbitDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("是否提交"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  saveOrder();
                },
              )
            ],
          );
        });
  }

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'STK_InStock';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = true;
      Map<String, dynamic> Model = Map();
      Model['FID'] = orderDate[0][14];
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[3]['value']['value'] != '0' &&
            double.parse(element[3]['value']['value']) >=
                element[9]['value']['value']) {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FEntryID'] = orderDate[hobbyIndex][4];
          FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FRealQty'] = element[3]['value']['value'];
          FEntityItem['FStockId'] = {"FNumber": element[4]['value']['value']};
          if (element[6]['value']['dimension'] != null && element[6]['value']['dimension'] != "") {
            FEntityItem['FStockLocId'] = {
              "FSTOCKLOCID__" + element[6]['value']['dimension']: {
                "FNumber": element[6]['value']['value']
              }
            };
          }
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量');
        return;
      }
      if (FEntity.length != orderDate.length) {
        this.isSubmit = false;
        ToastUtil.showInfo('入库数量和应收数量不一致,请检查');
        return;
      }
      Model['FInStockEntry'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      var params = jsonEncode(dataMap);
      if (orderDate[0][orderDate[0].length - 1] == "B") {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "STK_InStock",
          "data": {'Ids': orderDate[0][14]}
        };
        //审核
        HandlerOrder.orderHandler(context, submitMap, 3, "STK_InStock",
                SubmitEntity.audit(submitMap))
            .then((auditResult) async {
          if (auditResult) {
            var errorMsg = "";
            if (fBarCodeList == 1) {
              for (int i = 0; i < this.hobby.length; i++) {
                if (this.hobby[i][3]['value']['value'] != '0' &&
                    this.hobby[i][4]['value']['value'] != '') {
                  var kingDeeCode = this.hobby[i][0]['value']['kingDeeCode'];
                  for (int j = 0; j < kingDeeCode.length; j++) {
                    Map<String, dynamic> dataCodeMap = Map();
                    dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                    Map<String, dynamic> orderCodeMap = Map();
                    orderCodeMap['NeedReturnFields'] = [];
                    orderCodeMap['IsDeleteEntry'] = false;
                    Map<String, dynamic> codeModel = Map();
                    var itemCode = kingDeeCode[j].split("-");
                    codeModel['FID'] = itemCode[0];
                    codeModel['FOwnerID'] = {"FNUMBER": orderDate[i][20]};
                    codeModel['FStockOrgID'] = {"FNUMBER": orderDate[i][8]};
                    codeModel['FStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    codeModel['FLoc'] = this.hobby[i][6]['value']['label'];
                    /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                    Map<String, dynamic> codeFEntityItem = Map();
                    codeFEntityItem['FBillDate'] = FDate;
                    codeFEntityItem['FInQty'] = itemCode[1];
                    codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                    codeFEntityItem['FEntryStockID'] = {
                      "FNUMBER": this.hobby[i][4]['value']['value']
                    };
                    codeFEntityItem['FStockLocID'] = {
                      "FSTOCKLOCID__FF100001": {
                        "FNumber": this.hobby[i][6]['value']['label']
                      }
                    };
                    var codeFEntity = [codeFEntityItem];
                    codeModel['FEntity'] = codeFEntity;
                    orderCodeMap['Model'] = codeModel;
                    dataCodeMap['data'] = orderCodeMap;
                    String codeRes = await SubmitEntity.save(dataCodeMap);
                    var barcodeRes = jsonDecode(codeRes);
                    if (!barcodeRes['Result']['ResponseStatus']['IsSuccess']) {
                      errorMsg += "错误反馈：" +
                          itemCode[1] +
                          ":" +
                          barcodeRes['Result']['ResponseStatus']['Errors'][0]
                              ['Message'];
                    }
                  }
                }
              }
            }
            if (errorMsg != "") {
              ToastUtil.errorDialog(context, errorMsg);
              this.isSubmit = false;
            }
            //提交清空页面
            setState(() {
              this.hobby = [];
              this.orderDate = [];
              this.FBillNo = '';
              ToastUtil.showInfo('提交成功');
              Navigator.of(context).pop("refresh");
            });
          } else {
            setState(() {
              this.isSubmit = false;
            });
          }
        });
      } else {
        String order = await SubmitEntity.save(dataMap);
        var res = jsonDecode(order);
        print(res);
        if (res['Result']['ResponseStatus']['IsSuccess']) {
          Map<String, dynamic> submitMap = Map();
          submitMap = {
            "formid": "STK_InStock",
            "data": {
              'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
            }
          };
          //提交
          HandlerOrder.orderHandler(context, submitMap, 3, "STK_InStock",
                  SubmitEntity.submit(submitMap))
              .then((submitResult) {
            if (submitResult) {
              //审核
              HandlerOrder.orderHandler(context, submitMap, 3, "STK_InStock",
                      SubmitEntity.audit(submitMap))
                  .then((auditResult) async {
                if (auditResult) {
                  var errorMsg = "";
                  if (fBarCodeList == 1) {
                    for (int i = 0; i < this.hobby.length; i++) {
                      if (this.hobby[i][3]['value']['value'] != '0' &&
                          this.hobby[i][4]['value']['value'] != '') {
                        var kingDeeCode =
                            this.hobby[i][0]['value']['kingDeeCode'];
                        for (int j = 0; j < kingDeeCode.length; j++) {
                          Map<String, dynamic> dataCodeMap = Map();
                          dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                          Map<String, dynamic> orderCodeMap = Map();
                          orderCodeMap['NeedReturnFields'] = [];
                          orderCodeMap['IsDeleteEntry'] = false;
                          Map<String, dynamic> codeModel = Map();
                          var itemCode = kingDeeCode[j].split("-");
                          codeModel['FID'] = itemCode[0];
                          codeModel['FOwnerID'] = {"FNUMBER": orderDate[i][20]};
                          codeModel['FStockOrgID'] = {
                            "FNUMBER": orderDate[i][8]
                          };
                          codeModel['FStockID'] = {
                            "FNUMBER": this.hobby[i][4]['value']['value']
                          };
                          codeModel['FLoc'] =
                              this.hobby[i][6]['value']['label'];
                          /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                          Map<String, dynamic> codeFEntityItem = Map();
                          codeFEntityItem['FBillDate'] = FDate;
                          codeFEntityItem['FInQty'] = itemCode[1];
                          codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                          codeFEntityItem['FEntryStockID'] = {
                            "FNUMBER": this.hobby[i][4]['value']['value']
                          };
                          codeFEntityItem['FStockLocID'] = {
                            "FSTOCKLOCID__FF100001": {
                              "FNumber": this.hobby[i][6]['value']['label']
                            }
                          };
                          var codeFEntity = [codeFEntityItem];
                          codeModel['FEntity'] = codeFEntity;
                          orderCodeMap['Model'] = codeModel;
                          dataCodeMap['data'] = orderCodeMap;
                          print(dataCodeMap);
                          String codeRes = await SubmitEntity.save(dataCodeMap);
                          var barcodeRes = jsonDecode(codeRes);
                          if (!barcodeRes['Result']['ResponseStatus']
                              ['IsSuccess']) {
                            errorMsg += "错误反馈：" +
                                itemCode[1] +
                                ":" +
                                barcodeRes['Result']['ResponseStatus']['Errors']
                                    [0]['Message'];
                          }
                          print(codeRes);
                        }
                      }
                    }
                  }
                  if (errorMsg != "") {
                    ToastUtil.errorDialog(context, errorMsg);
                    this.isSubmit = false;
                  }
                  //提交清空页面
                  setState(() {
                    this.hobby = [];
                    this.orderDate = [];
                    this.FBillNo = '';
                    ToastUtil.showInfo('提交成功');
                    Navigator.of(context).pop("refresh");
                  });
                } else {
                  //失败后反审
                  HandlerOrder.orderHandler(context, submitMap, 3,
                          "STK_InStock", SubmitEntity.unAudit(submitMap))
                      .then((unAuditResult) {
                    if (unAuditResult) {
                      this.isSubmit = false;
                    } else {
                      this.isSubmit = false;
                    }
                  });
                }
              });
            } else {
              this.isSubmit = false;
            }
          });
        } else {
          setState(() {
            this.isSubmit = false;
            ToastUtil.errorDialog(context,
                res['Result']['ResponseStatus']['Errors'][0]['Message']);
          });
        }
      }
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("采购入库确认"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          /*title: TextWidget(FBillNoKey, '生产订单：'),*/
                          title: Text("单号：$fBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  _dateItem('日期：', DateMode.YMD),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('供应商:', this.supplierList, this.supplierName,
                        'supplier'),
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('部门', this.departmentList, this.departmentName,
                        'department'),
                  ),
                  //_item('部门', ['生产部'], '生产部'),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "备注",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._remarkContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _remarkContent.value = TextEditingValue(
                                    text: value,
                                    selection: TextSelection.fromPosition(
                                        TextPosition(
                                            affinity: TextAffinity.downstream,
                                            offset: value.length)));
                              });
                            },
                          ),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  /* Column(
                    children: this._getHobby(),
                  ),*/
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: this._getHobby2(),
                    ),
                  )
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async =>
                            this.isSubmit ? null : _showSumbitDialog(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
