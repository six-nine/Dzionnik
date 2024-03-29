import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:school_diary/constants.dart';
import 'package:school_diary/models/bell.dart';
import 'package:school_diary/services/database_helper.dart';
import 'package:school_diary/widgets/delete_modal_bottom_sheet.dart';
import 'package:school_diary/widgets/soft_button.dart';

class EditBells extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EditBellsState();
  }
}

class EditBellsState extends State<EditBells>{

  DatabaseHelper dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double itemWidth, itemHeight=122;

  List<Bell> bells = List<Bell>();

  String getTime(int s) {
    String ret;
    String h = (s ~/ 60).toString(), m = (s % 60).toString();
    if (m.length < 2) m = '0' + m;
    ret = h + ':' + m;
    return ret;
  }

  void updateBellsList() async {
    bells = await dbHelper.getBells();
    if (this.mounted)
    setState(() {
    });
  }

  showDeleteBellBottomSheet(int id){
    double screenWidth = MediaQuery.of(context).size.width;
    double margin = 14;
    double buttonWidth = (screenWidth - 3*margin)/2;
    showModalBottomSheet(context: context, builder: (context){
      return DeleteModalBottomSheet(
        buttonWidth: buttonWidth,
        text: "Вы уверены, что желаете удалить звонок из расписания?",
        onTap: () async {
          int res = await dbHelper.deleteBell(id);
          Navigator.of(context).pop();
          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: (res>=0) ? Text("Звонок успешно удалён из расписания") : Text("Ошибка"),
            backgroundColor: (res>=0) ? SoftColors.green : SoftColors.red,
          ));
        },
      );
    });
  }

  void updateBell(int order, int value, bool b){
    if (b) {
      if (order>0 && value<bells[order-1].end){
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            "Ошибка. Урок должен начинаться после окончания предыдущего.",
            style: TextStyle(
              fontSize: 15
            ),),
          backgroundColor: SoftColors.red,
        ));
        return;
      }
      bells[order].begin = value;
      bells[order].end = value+45;
      int i=order;
      while (i<bells.length-1 && bells[i].end>bells[i+1].begin) {
        bells[i+1].begin = bells[i].end;
        bells[i+1].end = bells[i+1].begin+45;
        dbHelper.updateBell(bells[i+1]);
        i++;
      }
      dbHelper.updateBell(bells[order]);
    }
    else {
      bells[order].end = value;
      dbHelper.updateBell(bells[order]);
      int i=order;
      while (i<bells.length-1 && bells[i].end>bells[i+1].begin) {
        bells[i+1].begin = bells[i].end;
        bells[i+1].end = bells[i+1].begin+45;
        dbHelper.updateBell(bells[i+1]);
        i++;
      }
      scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            "Расписание звонков обновлено",
            style: TextStyle(
              fontSize: 15
            ),),
            backgroundColor: SoftColors.green,
        ));
    }
  }

  Future<Null> selectTime(BuildContext context, int order, bool b) async {

    int currentHours = ((b) ? bells[order].begin : bells[order].end) ~/ 60;
    int currentMinutes = ((b) ? bells[order].begin : bells[order].end) % 60;

    DatePicker.showTimePicker(
      context,
      showTitleActions: true,
      locale: LocaleType.ru,
      showSecondsColumn: false,
      currentTime: DateTime(2016, 12, 21, currentHours, currentMinutes),
      onConfirm: (time){
        setState(() {
          int min = time.minute;
          int h = time.hour;
          updateBell(order, h*60+min, b);
        });
      }
    );

  }

  List<Widget> buildList(){
    double margin, width, screenWidth;
    screenWidth = MediaQuery.of(context).size.width;
    margin = 14;
    width = ((screenWidth-3*margin)/2);

    List<Widget> ret = List<Widget>();
    
    for (int i=0; i<bells.length; i++)
    ret.add(Container(
      decoration: BoxDecoration(
        boxShadow: UnpressedShadow.shadow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Container(
            child: SoftButton(
              onTap: (){
                showDeleteBellBottomSheet(bells[i].id);
              },
              color: SoftColors.blueLight,
              enableShadow: false,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                topLeft: Radius.circular(20),
              ),
              width: width,
              height: 60,
              child: Text(
                "${i+1} урок",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(height: 1, color: SoftColors.blueDark.withOpacity(0.5)),
          Container(
            child: Row(
              children: <Widget>[
                SoftButton(
                  color: SoftColors.blueLight,
                  enableShadow: false,
                  width: (width/2)-0.5,
                  height: 60,
                  child: Text(
                    getTime(bells[i].begin),
                    style: TextStyle(
                      color: SoftColors.blueDark
                    ),  
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20)
                  ),
                  onTap: (){
                    selectTime(context, i, true);
                  },
                ),
                
                Container(width: 1, color: SoftColors.blueDark.withOpacity(0.5), height: 60,),
                SoftButton(
                  color: SoftColors.blueLight,
                  enableShadow: false,
                  height: 60,
                  width: (width/2)-0.5,
                  child: Text(
                    getTime(bells[i].end),
                    style: TextStyle(
                      color: SoftColors.blueDark
                    ),  
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(20)
                  ),
                  onTap: (){
                    selectTime(context, i, false);
                  },
                )
              ],
            ),
          )
        ],
      ),
    ));

    ret.add(
      SoftButton(
        height: 121,
        color: SoftColors.blueLight,
        borderRadius: BorderRadius.circular(20),
        child: Icon(Icons.add, color: SoftColors.blueDark,),
        onTap: (){
          Bell newBell = (bells.length>0) 
            ? Bell(begin: bells[bells.length-1].end+10, end: bells[bells.length-1].end+55) 
            : Bell(begin: 60*8, end: 60*8+45);
            dbHelper.insertBell(newBell);
            setState(() {
            });
        },
      )
    );

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double margin = 14;
    itemWidth = ((screenWidth-3*margin)/2)-2;
    updateBellsList();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
          centerTitle: true,
          //leading: Logo(),
          iconTheme: IconThemeData(
              color: SoftColors.blueDark
          ),
          title: Text(
            "Расписание звонков",
            style: Styles.appBarTextStyle
          ),
          backgroundColor: SoftColors.blueLight,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: Container(
              height: 1,
              color: SoftColors.blueDark.withOpacity(0.5),
              width: MediaQuery.of(context).size.width * 0.9,
            ),
          )),
      body: Container(
        color: SoftColors.blueLight,
        child: GridView.count(
          padding: EdgeInsets.all(14),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          crossAxisCount: 2,
          children: buildList(),
          childAspectRatio: (itemWidth/itemHeight),
        ),
      )
      );
  }

}