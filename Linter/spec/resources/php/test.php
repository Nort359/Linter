<?php
namespace HivExam;

use Common\HivActions;
use Common\Sql\GetHivExamList;
use Common\Sql\GetBoolOptions;
use Common\Sql\SaveHivExamData;

/**
 * Обработчик для hiv_exam.list
 */
class HivExamList extends HivExamCommand
{
    /**
     * конструктор класса
     * @param int    $unitId        - идентификатор записи в разделе
     * @param ImpLog $oLog          - объект ImpLog для логирования отладочной информации
     * @param xml    $extResponse   - ответ внешней системы в формате XML
     */
    public function __construct($unitId, $oLog = null, $extResponse = null)
    {
        parent::__construct('hiv_exam.list', $unitId, $oLog, $extResponse, true);
    }

    /**
     * Получение объекта для SOAP-запроса
     * @return bool|object
     * @throws \Exception
     */
    public function getRequest()
    {
        if (!$this->checkParams()) {
            return false;
        }
        
        $registryKey = $this->xml->createElement('registryKey');
        $this->addElement($registryKey, 'registryNumber', $this->regNum);

        return $this->xml->saveXML($registryKey);
    }

    /**
     * Выполнение команды, переопределение функции-интерфейса
     * @param  int|null $sendResponseId - идентификатор сообщения
     * @return bool|string
     * @throws \Exception
     */
    public function execute($sendResponseId = null)
    {
        // прямой вызов сервиса - обрабатываем по умолчанию
        if (empty($this->response)) {
            return parent::executeDefault($sendResponseId);
        }
        // callback вызов сервиса - обрабатываем ответ
        if ($this->response->hasError()) {
            $this->logResponseError();
            return false;
        } elseif (GetBoolOptions::get('HIV_MASTER_DATA')) {
            // если сервис настроен на репликацию данных ФРВИЧ - сохраняем данные в БД
            $examOutList = $this->response->get('exams')->getElementsByTagName('exam');
            foreach ($examOutList as $examOut) {
                SaveHivExamData::set($this->response->xml->saveXML($examOut), null, $this->agentId, null, $this->oLog->getId());
            }
        } else {
            //получаем список исследований ФРВИЧ
            $examList = GetHivExamList::get($this->agentId, 0);
            foreach ($examList as $exam) {
                HivActions::executeList(['hiv_exam.read'], $sendResponseId, $exam['EXAM_ID'], $this->oLog);
            }
        }
        return true;
    }
}
