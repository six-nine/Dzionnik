import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:school_diary/constants.dart';
import 'package:school_diary/models/bell.dart';
import 'package:school_diary/models/scheduleItem.dart';
import 'package:school_diary/screens/editBells.dart';
import 'package:school_diary/services/database_helper.dart';
import 'package:school_diary/widgets/delete_modal_bottom_sheet.dart';
import 'package:sqflite/sqflite.dart';

class Timetable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return TimetableState();
  }
}

class TimetableState extends State<Timetable> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DatabaseHelper DBhelper = DatabaseHelper();
  Timer timer;
  int currentSelected = 1;
  int lesson = 3;
  int counter = 45;
  bool start = true;

  List<int> number;
  List<bool> active;
  List<int> weekday;
  List<bool> selected;
  List<Bell> bells;
  List<ScheduleItem> data;

  @override
  void initState() {
    super.initState();
  }

  navigateToEditBells(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditBells()));
    updateBellsList();
    setState(() {
    });
  }

  void addToDB(ScheduleItem item) async {
    int res = await DBhelper.insertScheduleItem(item);
  }

  showDeleteScheduleBottomSheet(ScheduleItem delItem){
    double screenWidth = MediaQuery.of(context).size.width;
    double margin = 14;
    double buttonWidth = (screenWidth - 3*margin)/2;
    showModalBottomSheet(context: context, builder: (context){
      return DeleteModalBottomSheet(
        buttonWidth: buttonWidth,
        text: "Вы действительно хотите удалить выбранный предмет из расписания?",
        onTap: () async {
          int res = await DBhelper.deleteScheduleItem(delItem.id);
          Navigator.of(context).pop();
          updateList();
          scaffoldKey.currentState.showSnackBar(SnackBar(
            content: (res>=0) ? Text("Предмет успешно удалён из расписания") : Text("Ошибка"),
            backgroundColor: (res>=0) ? SoftColors.green : SoftColors.red,
          ));
        },
      );
    });
  }

  void showEditItem(ScheduleItem item, bool add) {
    final titleController = TextEditingController();

    titleController.text = item.name;

    String name = item.name;
    Alert(
        context: context,
        title: add ? 'Добавить' : 'Редактировать',
        style: AlertStyle(
          animationType: AnimationType.fromBottom,
          backgroundColor: SoftColors.blueLight,
          titleStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          isCloseButton: false,
        ),
        content: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 25),
              child: TextField(
                controller: titleController,
                onChanged: (text) {
                  name = titleController.text;
                },
                style: TextStyle(),
                decoration: InputDecoration(
                    hintText: "Введите название",
                    hintStyle: TextStyle(fontSize: 15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)))),
              ),
            ),
            Container(
                margin: EdgeInsets.only(bottom: 15, top: 15),
                decoration: BoxDecoration(boxShadow: UnpressedShadow.shadow),
                child: DialogButton(
                  height: 45,
                  child: Text(add ? "Добавить" : "Сохранить",
                      style:
                          TextStyle(color: SoftColors.blueLight, fontSize: 20)),
                  radius: BorderRadius.circular(15),
                  color: SoftColors.blueDark,
                  //textColor: Colors.white,
                  onPressed: () {
                    item.name = name;
                    add
                        ? DBhelper.insertScheduleItem(item)
                        : DBhelper.updateSchedule(item);
                    Navigator.of(context).pop();
                    updateList();
                  },
                )),
            Container(
              decoration: BoxDecoration(boxShadow: UnpressedShadow.shadow),
              child: DialogButton(
                height: 45,
                child: Text("Отмена",
                    style: TextStyle(color: SoftColors.blueDark, fontSize: 20)),
                radius: BorderRadius.circular(15),
                color: SoftColors.blueLight,
                //textColor: Custom_Colors.blue,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        buttons: []).show();
  }

  void setTimer() {
    if (timer == null) {
      start = false;
      lesson = 69;
      int time = 60 * DateTime.now().hour + DateTime.now().minute;
      for (int i = 0; i < bells.length; i++) {
        if (bells[i].end >= time) {
          lesson = i + 1;
          start = (bells[i].begin <= time);
          if (start)
            counter = bells[i].end - time;
          else
            counter = bells[i].begin - time;
          break;
        }
      }
      if (lesson <= bells.length)
        timer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (this.mounted)
            setState(() {
              var now = DateTime.now();
              counter =
                  (start ? bells[lesson - 1].end : bells[lesson - 1].begin) -
                      (now.hour * 60 + now.minute);
              if (counter <= 0) {
                if (start) {
                  start = false;
                  lesson++;
                  if (lesson - 1 >= bells.length) {
                    timer.cancel();
                  } //else counter = bells[lesson - 1].begin - bells[lesson - 2].end;
                } else {
                  start = true;
                  if (lesson - 1 >= bells.length) timer.cancel();
                  //else counter = bells[lesson - 1].end - bells[lesson - 1].begin;
                }
              }
            });
        });
    }
  }

  void buildDatesList() {
    bool sunday = false;
    var now = DateTime.now();
    if (now.weekday == 7) {
      now = now.add(Duration(days: 1));
      sunday = true;
    }
    int d = 1 - now.weekday;
    while (d <= 0) {
      number.add(now.subtract(Duration(days: -d)).day);
      weekday.add(now.subtract(Duration(days: -d)).weekday);
      active.add(false);
      selected.add(false);
      d++;
    }
    if (!sunday) active[active.length - 1] = true;
    selected[active.length - 1] = true;
    currentSelected = active.length - 1;
    while (number.length < 6) {
      number.add(now.add(Duration(days: d)).day);
      weekday.add(now.add(Duration(days: d)).weekday);
      active.add(false);
      selected.add(false);
      d++;
    }
  }

  String getWeekday(int wd) {
    if (wd == 1) return "пн";
    if (wd == 2) return "вт";
    if (wd == 3) return "ср";
    if (wd == 4) return "чт";
    if (wd == 5) return "пт";
    if (wd == 6) return "сб";
    if (wd == 7) return "вс";
    return "ER";
  }

  String getMonth(int mon) {
    if (mon == 1) return "Январь";
    if (mon == 2) return "Февраль";
    if (mon == 3) return "Март";
    if (mon == 4) return "Апрель";
    if (mon == 5) return "Май";
    if (mon == 6) return "Июнь";
    if (mon == 7) return "Июль";
    if (mon == 8) return "Август";
    if (mon == 9) return "Сентябрь";
    if (mon == 10) return "Октябрь";
    if (mon == 11) return "Ноябрь";
    if (mon == 12) return "Декабрь";
    return "ERROR";
  }

  List<Widget> buildDates() {
    List<Widget> ret = List<Widget>();
    for (int i = 0; i < number.length; i++) {
      ret.add(Container(
        child: Column(
          children: <Widget>[
            Container(
              child: Text(getWeekday(weekday[i])),
            ),
            GestureDetector(
              onTap: () {
                selected[currentSelected] = false;
                selected[i] = true;
                currentSelected = i;
                setState(() {});
              },
              child: Container(
                child: Center(
                  child: Text(
                    number[i].toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: selected[i] ? Colors.white : Colors.black),
                  ),
                ),
                width: 40,
                height: 40,
                margin: EdgeInsets.only(top: 6, bottom: 10),
                decoration: BoxDecoration(
                    color:
                        selected[i] ? SoftColors.blueDark : Colors.transparent,
                    border: active[i]
                        ? Border.all(color: SoftColors.blueDark, width: 1)
                        : Border(),
                    boxShadow: selected[i]
                        ? UnpressedShadow.shadow
                        : [BoxShadow(color: Colors.transparent)],
                    shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ));
    }
    return ret;
  }

  String getTime(int s, int f) {
    String ret;
    String h = (s ~/ 60).toString(), m = (s % 60).toString();
    if (m.length < 2) m = '0' + m;
    ret = h + ':' + m + ' - ';
    h = (f ~/ 60).toString();
    m = (f % 60).toString();
    if (m.length < 2) m = '0' + m;
    ret += h + ':' + m;
    return ret;
  }

  List<Widget> buildList() {
    int j = -1;

    List<Widget> ret = List<Widget>();
    for (int i = 0; i < data.length; i++)
      if (data[i].weekday == currentSelected + 1) {
        j++;
        ret.add(
          Column(
            children: <Widget>[
              FlatButton(
                highlightColor: SoftColors.blueDark.withOpacity(0.1),
                onLongPress: () {
                  showDeleteScheduleBottomSheet(data[i]);
                },
                onPressed: () {
                  showEditItem(data[i], false);
                },
                child: ListTile(
                    title: Text(data[i].name),
                    subtitle: (j<bells.length) ? Text(getTime(bells[j].begin, bells[j].end)) : Text("Звонок не найден"),
                    leading: ((j >= lesson - 1 &&
                                data[i].weekday == DateTime.now().weekday) ||
                            data[i].weekday > DateTime.now().weekday ||
                            DateTime.now().weekday == 7)
                        ? Container(
                            width: 30,
                            height: 40,
                            child: Center(child: Icon(Icons.timer)))
                        : Container(
                            width: 30,
                            height: 40,
                            child: Center(
                                child: Icon(Icons.alarm_on,
                                    color: SoftColors.green))),
                    trailing: (ret.length == lesson - 1 &&
                            data[i].weekday == DateTime.now().weekday)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                                Text(counter.toString() + " мин",
                                    style:
                                        TextStyle(color: SoftColors.blueDark)),
                                Text((!start) ? "До начала" : "До конца",
                                    style: TextStyle(
                                        color: SoftColors.blueDark,
                                        fontSize: 10)),
                              ])
                        : Column()),
              ),
              Container(
                margin: EdgeInsets.only(right: 20, left: 20),
                height: 1,
                color: SoftColors.blueDark.withOpacity(0.2),
              )
            ],
          ),
        );
      }

    ret.add(FlatButton(
      highlightColor: SoftColors.blueDark.withOpacity(0.1),
      onPressed: () {
        showEditItem(
            ScheduleItem(
              weekday: currentSelected + 1,
              name: "",
            ),
            true);
      },
      child: Container(
          height: 60,
          alignment: Alignment(0, 0),
          child: Icon(
            Icons.add,
            color: SoftColors.blueDark,
          )),
    ));
    return ret;
  }

  void updateList() {
    final Future<Database> dbFuture = DBhelper.inicializeDatabase();
    dbFuture.then((database) {
      Future<List<ScheduleItem>> ListFuture = DBhelper.getScheduleItems();
      ListFuture.then((list) {
        setState(() {
          this.data = list;
        });
      });
    });
  }

  void updateBellsList() async {
    bells = await DBhelper.getBells();
  }

  @override
  Widget build(BuildContext context) {
    if (number == null) {
      number = List<int>();
      weekday = List<int>();
      active = List<bool>();
      selected = List<bool>();
      bells = List<Bell>();

      buildDatesList();
    }

    updateBellsList();

    if (data == null) {
      data = List<ScheduleItem>();
      updateList();
    }

    setTimer();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
          actions: <Widget>[
            IconButton(
              onPressed: () {
                navigateToEditBells(context);
              },
              icon: Icon(
                Icons.alarm,
                color: SoftColors.blueDark,
                size: 30,
              ),
            ),
          ],
          centerTitle: true,
          //leading: Logo(),
          leading: Container(
            child: SvgPicture.asset('assets/Dzlogo.svg'),
            padding: EdgeInsets.all(10),
          ),
          title: Text(
            "Расписание",
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
              //margin: EdgeInsets.only(bottom: 20),
            ),
          )),
      body: Container(
        width: MediaQuery.of(context).size.width,
        color: SoftColors.blueLight,
        child: ListView(
          children: <Widget>[
            Container(
                margin: EdgeInsets.only(top: 20, right: 20, left: 20),
                decoration: BoxDecoration(
                    color: SoftColors.blueLight,
                    boxShadow: UnpressedShadow.shadow,
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 10, bottom: 10),
                      child: Center(
                        child: Text(
                          getMonth(DateTime.now().month),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: buildDates(),
                    ),
                  ],
                )),
            Container(
              margin: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 40),
              //height: 1200,
              decoration: BoxDecoration(
                  color: SoftColors.blueLight,
                  boxShadow: UnpressedShadow.shadow,
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              child: Column(
                children: buildList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
