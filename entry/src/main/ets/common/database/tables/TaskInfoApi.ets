import dataRdb from '@ohos.data.relationalStore';
import TaskInfo from '../../../viewmodel/TaskInfo';
import { CommonConstants as Const } from '../../constants/CommonConstants';
import RdbUtils from '../rdb/RdbUtils';
import Logger from '../../utils/Logger';

class TaskInfoApi {
  insertData(taskInfo: TaskInfo, callback: Function): void {
    const valueBucket = generateBucket(taskInfo);
    RdbUtils.insert('taskInfo', valueBucket).then(result => {
      callback(result);
    });
    Logger.info('TaskInfoTable', `Insert taskInfo {${taskInfo.date}:${taskInfo.taskID}} finished.`);
  }

  deleteDataByID(taskInfo: TaskInfo, callback: Function): void {
    let tableName = Const.TASK_INFO.tableName;
    if (!tableName) {
      return;
    }
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.equalTo('date', taskInfo.date).and().equalTo('taskID', taskInfo.taskID);
    RdbUtils.del(predicates).then(result => {
      callback(result);
    });
    Logger.info('TaskInfoTable', `Delete taskInfo {${taskInfo.date}:${taskInfo.taskID}} finished.`);
  }

  updateDataByDate(taskInfo: TaskInfo, callback: Function): void {
    const valueBucket = generateBucket(taskInfo);
    let tableName = Const.TASK_INFO.tableName;
    if (!tableName) {
      return;
    }
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.equalTo('date', taskInfo.date).and().equalTo('taskID', taskInfo.taskID);
    RdbUtils.update(valueBucket, predicates).then((result: number) => {
      callback(result);
    });
    Logger.info('TaskInfoTable', `Update data {${taskInfo.date}:${taskInfo.taskID}} finished.`);
  }

  query(date: string, isOpen: boolean = true, callback: Function): void {
    let tableName = Const.TASK_INFO.tableName;
    if (!tableName) {
      return;
    }
    let predicates = new dataRdb.RdbPredicates(tableName);
    predicates.equalTo('date', date);
    if (isOpen) {
      predicates.equalTo('isOpen', true);
    }
    predicates.orderByAsc('taskID');
    RdbUtils.query(predicates).then(resultSet => {
      let count = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        Logger.error('TaskInfoTable', `${date} query no results!`);
        const result: TaskInfo[] = [];
        callback(result);
      } else {
        resultSet.goToFirstRow();
        const result: TaskInfo[] = [];
        for (let i = 0; i < count; i++) {
          let tmp = TaskInfo.create(0, '');
          tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
          tmp.date = resultSet.getString(resultSet.getColumnIndex('date'));
          tmp.taskID = resultSet.getDouble(resultSet.getColumnIndex('taskID'));
          tmp.taskName = resultSet.getString(resultSet.getColumnIndex('taskName'));
          tmp.taskType = resultSet.getDouble(resultSet.getColumnIndex('taskType'));
          tmp.targetValue = resultSet.getString(resultSet.getColumnIndex('targetValue'));
          tmp.finValue = resultSet.getString(resultSet.getColumnIndex('finValue'));
          tmp.unit = resultSet.getString(resultSet.getColumnIndex('unit'));
          tmp.isAlarm = resultSet.getDouble(resultSet.getColumnIndex('isAlarm')) ? true : false;
          tmp.startTime = resultSet.getString(resultSet.getColumnIndex('startTime'));
          tmp.endTime = resultSet.getString(resultSet.getColumnIndex('endTime'));
          tmp.frequency = resultSet.getString(resultSet.getColumnIndex('frequency'));
          tmp.isDone = resultSet.getDouble(resultSet.getColumnIndex('isDone')) ? true : false;
          tmp.isOpen = resultSet.getDouble(resultSet.getColumnIndex('isOpen')) ? true : false;
          tmp.status = resultSet.getDouble(resultSet.getColumnIndex('status'));
          tmp.subTasks = resultSet.getString(resultSet.getColumnIndex('subTasks'));
          tmp.cycleDays = resultSet.getString(resultSet.getColumnIndex('cycleDays'));
          tmp.cycleTarget = resultSet.getDouble(resultSet.getColumnIndex('cycleTarget'));
          tmp.dataSrc = resultSet.getString(resultSet.getColumnIndex('dataSrc'));
          tmp.inputHistory = resultSet.getString(resultSet.getColumnIndex('inputHistory'));
          result[i] = tmp;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }
}

function generateBucket(taskInfo: TaskInfo): dataRdb.ValuesBucket {
  let valueBucket = {} as dataRdb.ValuesBucket;
  Const.TASK_INFO.columns?.forEach((item: string) => {
    if (item !== 'id') {
      switch (item) {
        case 'date':
          valueBucket[item] = taskInfo.date;
          break;
        case 'taskID':
          valueBucket[item] = taskInfo.taskID;
          break;
        case 'taskName':
          valueBucket[item] = taskInfo.taskName;
          break;
        case 'taskType':
          valueBucket[item] = taskInfo.taskType;
          break;
        case 'targetValue':
          valueBucket[item] = taskInfo.targetValue;
          break;
        case 'finValue':
          valueBucket[item] = taskInfo.finValue;
          break;
        case 'unit':
          valueBucket[item] = taskInfo.unit;
          break;
        case 'isAlarm':
          valueBucket[item] = taskInfo.isAlarm;
          break;
        case 'startTime':
          valueBucket[item] = taskInfo.startTime;
          break;
        case 'endTime':
          valueBucket[item] = taskInfo.endTime;
          break;
        case 'frequency':
          valueBucket[item] = taskInfo.frequency;
          break;
        case 'isDone':
          valueBucket[item] = taskInfo.isDone;
          break;
        case 'isOpen':
          valueBucket[item] = taskInfo.isOpen;
          break;
        case 'status':
          valueBucket[item] = taskInfo.status;
          break;
        case 'subTasks':
          valueBucket[item] = taskInfo.subTasks;
          break;
        case 'cycleDays':
          valueBucket[item] = taskInfo.cycleDays;
          break;
        case 'cycleTarget':
          valueBucket[item] = taskInfo.cycleTarget;
          break;
        case 'dataSrc':
          valueBucket[item] = taskInfo.dataSrc;
          break;
        case 'inputHistory':
          valueBucket[item] = taskInfo.inputHistory;
          break;
        default:
          break;
      }
    }
  });
  return valueBucket;
}

let taskInfoApi = new TaskInfoApi();

export default taskInfoApi as TaskInfoApi;
