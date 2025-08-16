# verl/utils/reward_score/my_reward.py
import re
# from bert_score import BERTScorer  # 서술형 정답 평가용 (bert-score 패키지)

# 평가에 사용할 정규식 패턴들 정의
match_format = re.compile(r"정답:(.+)")            # '정답:'으로 시작하는 최종 답 부분 추출
english_word_re = re.compile(r'[A-Za-z]{2,}')      # 알파벳 2글자 이상 단어
paren_re = re.compile(r'\([^)]*\)')               # 괄호(...) 안의 내용 제거용

# BERTScore 계산기 초기화 (한국어 지원 모델)
# bert_scorer = BERTScorer(lang="ko", model_type="bert-base-multilingual-cased", rescale_with_baseline=True)

def compute_score(data_source, solution_str, ground_truth, extra_info=None):
    # 0. 초기 점수 설정
    total_score = 0.0

    # 1. 출력 형식 검사: "정답:"으로 시작하는 답 추출
    match = match_format.findall(solution_str.strip())

    response_wo_paren = paren_re.sub('', solution_str)
    if len(english_word_re.findall(response_wo_paren)) >= 3:
        total_score -= 0.1
                
    if not match:
        # 형식 불일치: "정답:" 패턴이 없으면 0점 반환 (페널티 적용 가능)
        # 영어 페널티만 적용 (형식 자체가 틀렸으므로 보상 없음)
        # 영어 단어 개수 세서 페널티 부여
        
        return total_score  # 형식 오류이면 (페널티 적용 후) 반환

    # 형식이 올바르면 일정 점수 부여 (예: 0.1점 기본 지급)
    total_score += 0.1
    pred_answer = match[0].strip()         # "정답:" 뒤에 나온 모델의 답안 부분
    # 불필요한 태그 제거 검사
    # if any(tag in pred_answer for tag in ("<think>", "</think>", "<answer>")):
    #     # 정답 부분에 금지 태그가 포함된 경우 형식 위반으로 0점 처리
    #     return 0.0

    # 2. 문제 유형 파악 (data_source나 extra_info를 통해 받았다면 활용, 없으면 정답 형태로 유추)
    qtype = None
    # 예: extra_info에 {'question_type': '선다형'} 등이 담겨있는 경우
    if extra_info and "question_type" in extra_info:
        qtype = extra_info["question_type"]
    # data_source로 유형을 구분하는 경우 (예: data_source 값에 'multiple_choice' 등 포함)
    elif data_source and "선다형" in data_source:
        qtype = "선다형"
    elif data_source and "단답형" in data_source:
        qtype = "단답형"
    # 유형 정보를 별도로 받지 못한 경우: 정답 데이터 형태로 추정
    if qtype is None:
        # ground_truth가 한 자리 숫자면 선다형으로 간주 (예외적으로 단답형 정답이 숫자 1자리인 경우는 드물다고 가정)
        if re.fullmatch(r'[1-5]', str(ground_truth).strip()):
            qtype = "선다형"
        else:
            # 복수 정답 구분자 존재하면 단답형
            if '#' in str(ground_truth) or ',' in str(ground_truth):
                qtype = "단답형"
            else:
                qtype = "단답형"  # 기본은 단답형으로 처리 (서술형은 별도 표시된 경우에만)

    # 3. 정답 정확도 평가
    correct_score = 0.0
    true_answer = str(ground_truth).strip()
    if qtype == "선다형":
        # 모델 출력에서 숫자 추출
        nums = re.findall(r"[1-5]", pred_answer)
        pred_choice = nums[0] if nums else pred_answer  # 숫자가 있으면 첫 번째만 사용
        if pred_choice == true_answer:
            correct_score = 1.0
    elif qtype == "단답형":
        # 정답 후보가 '#'로 연결된 경우: 여러 개 중 하나 맞추면 정답
        if '#' in true_answer:
            for t_ans in true_answer.split('#'):
                if pred_answer.replace('*','').replace(' ','') == t_ans.replace(' ',''):
                    correct_score = 1.0
                    break
        # 정답이 콤마로 연결된 경우: 여러 요소 모두 포함하면 정답
        elif ',' in true_answer:
            pred_set = {x.replace('*','').strip() for x in pred_answer.split(',')}
            true_set = {x.strip() for x in true_answer.split(',')}
            if true_set == pred_set:
                correct_score = 1.0
        else:
            # 일반 단답: 공백과 특정 문자 제거 후 정확히 일치하면 정답
            if pred_answer.replace('*','').replace(' ','') == true_answer.replace(' ',''):
                correct_score = 1.0
    # else:  # 서술형 (qtype == "서술형")
    #     # BERTScore로 유사도 계산 (F1 스코어 사용)
    #     P, R, F1 = bert_scorer.score([solution_str], [true_answer])
    #     f1_score = F1.item()
    #     # 임계값 등은 별도로 설정 가능하나, 여기서는 F1 그대로 사용
    #     correct_score = f1_score  # 0~1 사이 값

    # 4. 점수 합산: 형식 점수(0.1) + 정답 점수
    # if correct_score >= 1.0:
        # 정답 완전 일치인 경우 최대 1.0점으로 설정 (형식점수 0.1 포함했으므로 1.0로 클립)
        # total_score = 1.0
    # else:
    # 정답이 틀린 경우에는 형식 점수(0.1)만 유지 (correct_score는 0)
    total_score += correct_score  # 틀리면 0 증가, 맞으면 위에서 1.0으로 처리

    # 5. 영어 남용 페널티 적용
    # response_wo_paren = paren_re.sub('', solution_str)
    # english_words = english_word_re.findall(response_wo_paren)
    # if len(english_words) >= 3:
    #     total_score -= 0.5

    # 최소 0점은 보장 (페널티로 음수가 될 경우 0으로 바꿈)
    # if total_score < 0:
    #     total_score = 0.0
    return total_score
