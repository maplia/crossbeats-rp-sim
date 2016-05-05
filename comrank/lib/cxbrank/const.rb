require 'bigdecimal'

module CxbRank
  # エンジン名
  ENGINE_NAME = 'CxB RankPoint Simulator REV.'
  ENGINE_VERSION = '1.4.1'

  # URI
  SITE_TOP_URI = '/'                                # サイトトップ
  USAGE_URI = '/usage'                              # 使い方案内
  USER_ADD_URI = '/user_add'                        # ユーザ新規登録
  USER_EDIT_URI = '/user_edit'                      # ユーザ情報編集
  USER_LOGIN_URI = '/login'                         # ユーザログイン
  USER_LOGOUT_URI = '/logout'                       # ユーザログアウト
  USER_LIST_URI = '/user_list'                      # ユーザ一覧
  SKILL_LIST_VIEW_URI = '/view'                     # 公開スキル表
  SKILL_LIST_VIEW_IGLOCK_URI = '/iglock'            # 公開スキル表（ロック無視版）
  CLEAR_LIST_VIEW_URI = '/chart'                    # 公開クリア表
  SKILL_LIST_EDIT_URI = '/list'                     # ユーザ側スキル表
  SKILL_ITEM_EDIT_URI = '/edit'                     # スキル情報編集（単曲）
  SKILL_COURSE_ITEM_EDIT_URI = '/edit_course'       # スキル情報編集（コース）

  MAX_SKILL_VIEW_URI = '/max_view'                  # 理論値スキル表
  MAX_SKILL_VIEW_IGLOCK_URI = '/max_iglock'         # 理論値スキル表（ロック無視版）

  MUSIC_LIST_VIEW_URI = '/musics'                   # 登録曲リスト
  RANK_CALC_URI = '/rankcalc'                       # 許容ミス数計算機
  RATE_CALC_URI = '/scorerate'                      # 得点率計算機
  EVENT_SHEET_URI = '/sheet'                        # イベントスコアシート

  # ページ名
  PAGE_TITLES = {
    SITE_TOP_URI =>               'トップ',
    USAGE_URI =>                  '使い方案内',
    MUSIC_LIST_VIEW_URI =>        '登録曲リスト',
    USER_ADD_URI =>               '新規ユーザー登録',
    USER_EDIT_URI =>              'ユーザー情報編集',
    USER_LIST_URI =>              '登録ユーザーリスト',
    SKILL_LIST_EDIT_URI =>        'ランクポイント表',
    SKILL_LIST_VIEW_URI =>        'ランクポイント表',
    SKILL_LIST_VIEW_IGLOCK_URI => 'ランクポイント表',
    MAX_SKILL_VIEW_URI =>         '理論値ランクポイント表',
    MAX_SKILL_VIEW_IGLOCK_URI =>  '理論値ランクポイント表',
    CLEAR_LIST_VIEW_URI =>        'クリア状況表',
    SKILL_ITEM_EDIT_URI =>        'ランクポイント編集',
    SKILL_COURSE_ITEM_EDIT_URI => 'ランクポイント編集',
    RANK_CALC_URI =>              'ランク/レート別許容ミス数計算機',
    RATE_CALC_URI =>              '得点率計算ツール',
    EVENT_SHEET_URI =>            'イベントスコアシート',
  }

  # 画像ファイルを置いておくディレクトリへのパス
  IMAGE_PATH = 'images/'

  # プログラムの設定ファイル
  CONFIG_FILE = 'config/config.yml'
  DATABASE_FILE = 'config/database.yml'

  # 動作モード
  MODE_CXB = 'cxb'
  MODE_REV = 'rev'
  MODE_REV_SUNRISE = 'rev_sunrise'

  # レベル表記
  LEVEL_FORMATS = {
    MODE_CXB         => '%.1f',
    MODE_REV         => '%d',
  }
  LEVEL_FORMATS[MODE_REV_SUNRISE] = LEVEL_FORMATS[MODE_REV]

  # 日付範囲下限値
  DATE_LOW_LIMITS = {
    MODE_CXB         => Date.parse('2013-12-02'),
    MODE_REV         => Date.parse('2015-07-23'),
    MODE_REV_SUNRISE => Date.parse('2016-04-28'),
  }
  # ULTIMATEモード導入日
  ULTIMATE_START_DATE = {
    MODE_CXB         => Date.parse('2014-01-08'),
    MODE_REV         => DATE_LOW_LIMITS[MODE_REV],
    MODE_REV_SUNRISE => DATE_LOW_LIMITS[MODE_REV_SUNRISE],
  }

  # 編集操作モード
  OPERATION_UPDATE = 'update'
  OPERATION_UPDATE_MODE = '登録'
  OPERATION_DELETE = 'delete'
  OPERATION_DELETE_MODE = '削除'
  OPERATIONS = {
    OPERATION_UPDATE => OPERATION_UPDATE_MODE,
    OPERATION_DELETE => OPERATION_DELETE_MODE,
  }

  # 曲種別定数
  MUSIC_TYPE_NORMAL = 1
  MUSIC_TYPE_NORMAL_NAME = '一般曲'
  MUSIC_TYPE_SPECIAL = 0
  MUSIC_TYPE_SPECIAL_NAME = '期間限定RP対象曲'
  MUSIC_TYPE_REV_SINGLE = 10
  MUSIC_TYPE_REV_SINGLE_NAME = 'MUSIC PLAY'
  MUSIC_TYPE_REV_BONUS = 11
  MUSIC_TYPE_REV_BONUS_NAME = 'UNL BONUS'
  MUSIC_TYPE_REV_COURSE = 12
  MUSIC_TYPE_REV_COURSE_NAME = 'CHALLENGE'
  MUSIC_TYPE_REV_LIMITED = 13
  MUSIC_TYPE_REV_LIMITED_NAME = '期間限定曲（RP対象外）'
  MUSIC_TYPES = {
    MODE_CXB => {
      MUSIC_TYPE_NORMAL      => MUSIC_TYPE_NORMAL_NAME,
      MUSIC_TYPE_SPECIAL     => MUSIC_TYPE_SPECIAL_NAME,
    },
    MODE_REV => {
      MUSIC_TYPE_REV_SINGLE  => MUSIC_TYPE_REV_SINGLE_NAME,
      MUSIC_TYPE_REV_BONUS   => MUSIC_TYPE_REV_BONUS_NAME,
      MUSIC_TYPE_REV_COURSE  => MUSIC_TYPE_REV_COURSE_NAME,
      MUSIC_TYPE_REV_LIMITED => MUSIC_TYPE_REV_LIMITED_NAME,
    }
  }
  MUSIC_TYPES[MODE_REV_SUNRISE] = MUSIC_TYPES[MODE_REV]
  # 曲種別ごとの最大スキル対象曲数
  MUSIC_TYPE_ST_COUNTS = {
    MUSIC_TYPE_NORMAL      => 20,
    MUSIC_TYPE_SPECIAL     => nil,
    MUSIC_TYPE_REV_SINGLE  => 20,
    MUSIC_TYPE_REV_BONUS   => nil,
    MUSIC_TYPE_REV_COURSE  => 1,
    MUSIC_TYPE_REV_LIMITED => 0,
  }

  # 譜面難度種別定数
  MUSIC_DIFF_ESY = 1
  MUSIC_DIFF_ESY_NAME = 'ESY'
  MUSIC_DIFF_STD = 2
  MUSIC_DIFF_STD_NAME = 'STD'
  MUSIC_DIFF_HRD = 3
  MUSIC_DIFF_HRD_NAME = 'HRD'
  MUSIC_DIFF_MAS = 4
  MUSIC_DIFF_MAS_NAME = 'MAS'
  MUSIC_DIFF_UNL = 5
  MUSIC_DIFF_UNL_NAME = 'UNL'
  MUSIC_DIFFS = {
    MODE_CXB => {
      MUSIC_DIFF_STD => MUSIC_DIFF_STD_NAME,
      MUSIC_DIFF_HRD => MUSIC_DIFF_HRD_NAME,
      MUSIC_DIFF_MAS => MUSIC_DIFF_MAS_NAME,
    },
    MODE_REV => {
      MUSIC_DIFF_ESY => MUSIC_DIFF_ESY_NAME,
      MUSIC_DIFF_STD => MUSIC_DIFF_STD_NAME,
      MUSIC_DIFF_HRD => MUSIC_DIFF_HRD_NAME,
      MUSIC_DIFF_MAS => MUSIC_DIFF_MAS_NAME,
      MUSIC_DIFF_UNL => MUSIC_DIFF_UNL_NAME,
    },
  }
  MUSIC_DIFFS[MODE_REV_SUNRISE] = MUSIC_DIFFS[MODE_REV]
  MUSIC_DIFF_PREFIXES = {
    MUSIC_DIFF_ESY => MUSIC_DIFF_ESY_NAME.downcase,
    MUSIC_DIFF_STD => MUSIC_DIFF_STD_NAME.downcase,
    MUSIC_DIFF_HRD => MUSIC_DIFF_HRD_NAME.downcase,
    MUSIC_DIFF_MAS => MUSIC_DIFF_MAS_NAME.downcase,
    MUSIC_DIFF_UNL => MUSIC_DIFF_UNL_NAME.downcase,
  }
  MUSIC_DIFF_CLASSES = MUSIC_DIFF_PREFIXES

  # スキルポイント情報ステータス定数
  SP_STATUS_NO_PLAY = 0
  SP_STATUS_NO_PLAY_NAME = 'プレイなし'
  SP_STATUS_CLEAR = 1
  SP_STATUS_CLEAR_NAME = 'クリア'
  SP_STATUS_FAILED = 2
  SP_STATUS_FAILED_NAME = 'クリア失敗'
  SP_STATUSES = {
    SP_STATUS_NO_PLAY => SP_STATUS_NO_PLAY_NAME,
    SP_STATUS_CLEAR   => SP_STATUS_CLEAR_NAME,
    SP_STATUS_FAILED  => SP_STATUS_FAILED_NAME,
  }

  # スキルポイント情報ステータス定数（チャレンジ）
  SP_COURSE_STATUS_NO_PLAY = 0
  SP_COURSE_STATUS_NO_PLAY_NAME = 'プレイなし'
  SP_COURSE_STATUS_CLEAR = 1
  SP_COURSE_STATUS_CLEAR_NAME = '完奏'
  SP_COURSE_STATUS_FAILED = 2
  SP_COURSE_STATUS_FAILED_NAME = '失敗'
  SP_COURSE_STATUSES = {
    SP_COURSE_STATUS_NO_PLAY => SP_COURSE_STATUS_NO_PLAY_NAME,
    SP_COURSE_STATUS_CLEAR   => SP_COURSE_STATUS_CLEAR_NAME,
    SP_COURSE_STATUS_FAILED  => SP_COURSE_STATUS_FAILED_NAME,
  }

  # プレイ判定定数
  SP_RANK_STATUS_NO = 0
  SP_RANK_STATUS_NO_NAME = ''
  SP_RANK_STATUS_SPP = 1
  SP_RANK_STATUS_SPP_NAME = 'S++'.gsub(/\+/, '&#x2b;')
  SP_RANK_STATUS_SP = 2
  SP_RANK_STATUS_SP_NAME = 'S+'
  SP_RANK_STATUS_S = 3
  SP_RANK_STATUS_S_NAME = 'S'
  SP_RANK_STATUS_AP = 4
  SP_RANK_STATUS_AP_NAME = 'A+'
  SP_RANK_STATUS_A = 5
  SP_RANK_STATUS_A_NAME = 'A'
  SP_RANK_STATUS_BP = 6
  SP_RANK_STATUS_BP_NAME = 'B+'
  SP_RANK_STATUS_B = 7
  SP_RANK_STATUS_B_NAME = 'B'
  SP_RANK_STATUS_C = 8
  SP_RANK_STATUS_C_NAME = 'C'
  SP_RANK_STATUS_D = 9
  SP_RANK_STATUS_D_NAME = 'D'
  SP_RANK_STATUS_E = 10
  SP_RANK_STATUS_E_NAME = 'E'
  SP_RANK_STATUSES = {
    SP_RANK_STATUS_NO  => SP_RANK_STATUS_NO_NAME,
    SP_RANK_STATUS_SPP => SP_RANK_STATUS_SPP_NAME,
    SP_RANK_STATUS_SP  => SP_RANK_STATUS_SP_NAME,
    SP_RANK_STATUS_S   => SP_RANK_STATUS_S_NAME,
    SP_RANK_STATUS_AP  => SP_RANK_STATUS_AP_NAME,
    SP_RANK_STATUS_A   => SP_RANK_STATUS_A_NAME,
    SP_RANK_STATUS_BP  => SP_RANK_STATUS_BP_NAME,
    SP_RANK_STATUS_B   => SP_RANK_STATUS_B_NAME,
    SP_RANK_STATUS_C   => SP_RANK_STATUS_C_NAME,
    SP_RANK_STATUS_D   => SP_RANK_STATUS_D_NAME,
    SP_RANK_STATUS_E   => SP_RANK_STATUS_E_NAME,
  }
  SP_RANK_STATUS_OPTIONS = [
    [SP_RANK_STATUS_NO_NAME,  SP_RANK_STATUS_NO],
    [SP_RANK_STATUS_SPP_NAME, SP_RANK_STATUS_SPP],
    [SP_RANK_STATUS_SP_NAME,  SP_RANK_STATUS_SP],
    [SP_RANK_STATUS_S_NAME,   SP_RANK_STATUS_S],
    [SP_RANK_STATUS_AP_NAME,  SP_RANK_STATUS_AP],
    [SP_RANK_STATUS_A_NAME,   SP_RANK_STATUS_A],
    [SP_RANK_STATUS_BP_NAME,  SP_RANK_STATUS_BP],
    [SP_RANK_STATUS_B_NAME,   SP_RANK_STATUS_B],
    [SP_RANK_STATUS_C_NAME,   SP_RANK_STATUS_C],
    [SP_RANK_STATUS_D_NAME,   SP_RANK_STATUS_D],
    [SP_RANK_STATUS_E_NAME,   SP_RANK_STATUS_E],
  ]

  # コンボ判定定数
  SP_COMBO_STATUS_NO = 0
  SP_COMBO_STATUS_NO_NAME = ''
  SP_COMBO_STATUS_FC = 1
  SP_COMBO_STATUS_FC_NAME = 'FC'
  SP_COMBO_STATUS_EX = 2
  SP_COMBO_STATUS_EX_NAME = 'EXC'
  SP_COMBO_STATUSES = {
    SP_COMBO_STATUS_NO => SP_COMBO_STATUS_NO_NAME,
    SP_COMBO_STATUS_FC => SP_COMBO_STATUS_FC_NAME,
    SP_COMBO_STATUS_EX => SP_COMBO_STATUS_EX_NAME
  }
  SP_COMBO_STATUS_OPTIONS = [
    [SP_COMBO_STATUS_NO_NAME, SP_COMBO_STATUS_NO],
    [SP_COMBO_STATUS_FC_NAME, SP_COMBO_STATUS_FC],
    [SP_COMBO_STATUS_EX_NAME, SP_COMBO_STATUS_EX],
  ]

  # ゲージ設定定数
  SP_GAUGE_NORMAL = 0
  SP_GAUGE_NORMAL_NAME = ''
  SP_GAUGE_ULTIMATE_CXB = 1
  SP_GAUGE_ULTIMATE_CXB_NAME = 'ULT'
  SP_GAUGE_SURVIVAL_REV = 1
  SP_GAUGE_SURVIVAL_REV_NAME = 'SURV'
  SP_GAUGE_ULTIMATE_REV = 2
  SP_GAUGE_ULTIMATE_REV_NAME = 'ULT'
  SP_GAUGE_SURVIVAL_REV_SUNRISE_NAME = 'SUV'
  SP_GAUGES = {
    MODE_CXB => {
      SP_GAUGE_NORMAL       => SP_GAUGE_NORMAL_NAME,
      SP_GAUGE_ULTIMATE_CXB => SP_GAUGE_ULTIMATE_CXB_NAME,
    },
    MODE_REV => {
      SP_GAUGE_NORMAL       => SP_GAUGE_NORMAL_NAME,
      SP_GAUGE_SURVIVAL_REV => SP_GAUGE_SURVIVAL_REV_NAME,
      SP_GAUGE_ULTIMATE_REV => SP_GAUGE_ULTIMATE_REV_NAME,
    },
    MODE_REV_SUNRISE => {
      SP_GAUGE_NORMAL       => SP_GAUGE_NORMAL_NAME,
      SP_GAUGE_SURVIVAL_REV => SP_GAUGE_SURVIVAL_REV_SUNRISE_NAME,
      SP_GAUGE_ULTIMATE_REV => SP_GAUGE_ULTIMATE_REV_NAME,
    },
  }
  SP_GAUGE_STATUS_OPTIONS = [
    [SP_GAUGE_NORMAL_NAME,               SP_GAUGE_NORMAL],
    [SP_GAUGE_SURVIVAL_REV_SUNRISE_NAME, SP_GAUGE_SURVIVAL_REV],
    [SP_GAUGE_ULTIMATE_REV_NAME,         SP_GAUGE_ULTIMATE_REV],
  ]

  # ゲージ・難易度によるボーナスレート
  BONUS_RATE_SURVIVAL = BigDecimal.new('1.1')
  BONUS_RATE_ULTIMATE = BigDecimal.new('1.2')
  BONUS_RATE_NONE = BigDecimal.new('1.0')
  BONUS_RATE_UNLIMITED = BigDecimal.new('0.01')

  # ID桁数
  USER_ID_FIGURE = 5          # ユーザID

  # 入力受付桁数
  POINT_FIGURE = 6            # RP入力の最大桁数（0.00～xxx.xx）
  SCORE_FIGURE = 5            # スコアの最大桁数
  RATE_FIGURE = 6             # 達成率入力の最大桁数（0.00～100.00）
  COURSE_RATE_FIGURE = 5      # 達成率入力の最大桁数（0.0～100.0）
  GAME_ID_FIGURE = 8          # ゲームIDの桁数

  # セッションの有効期限（単位: 分）
  EXPIRE_MINUTES = 60

  # エラー/エラーメッセージ定数
  # 定数名の英語はてきとー（逃げ
  NO_ERROR = '0'        # エラーなし
  # セッション関係
  ERROR_SESSION_IS_DEAD = '00'
  ERROR_SESSION_IS_DEAD_TEXT = "以下のいずれかによるエラーです。</p><ul><li>セッションの有効期限が切れている（最終アクセスから#{EXPIRE_MINUTES}分以上経過）</li><li>正規のログイン手続きを踏んでいないアクセス</li></ul><p>トップページに戻って、ログインし直してください。"
  ERROR_SESSION_IS_FINISHED = '01'
  ERROR_SESSION_IS_FINISHED_TEXT = 'ログアウトしました。'
  # セキュリティチェック
  ERROR_INVALID_ACCESS = '06'
  ERROR_INVALID_ACCESS_TEXT = '不正なアクセスです。'
  # データベースエラー
  ERROR_DATABASE_SAVE_FAILED = '09'
  ERROR_DATABASE_SAVE_FAILED_TEXT = 'データベースの更新に失敗しました。操作をやり直してください。'
  # ユーザ登録/編集関係
  ERROR_USERNAME_IS_UNINPUTED = '11'
  ERROR_USERNAME_IS_UNINPUTED_TEXT = 'ユーザー名が入力されていません。'
  ERROR_PASSWORD1_IS_UNINPUTED = '12'
  ERROR_PASSWORD1_IS_UNINPUTED_TEXT = 'パスワードが入力されていません。'
  ERROR_PASSWORD2_IS_UNINPUTED = '13'
  ERROR_PASSWORD2_IS_UNINPUTED_TEXT = '確認用のパスワードが入力されていません。'
  ERROR_PASSWORDS_ARE_NOT_EQUAL = '14'
  ERROR_PASSWORDS_ARE_NOT_EQUAL_TEXT = '入力されたパスワードが一致しません。'
  ERROR_GAME_ID_NOT_NUMERIC = '15'
  ERROR_GAME_ID_NOT_NUMERIC_TEXT = 'ゲームIDが正しい数字ではありません。'
  ERROR_GAME_ID_LENGTH_IS_INVALID = '16'
  ERROR_GAME_ID_LENGTH_IS_INVALID_TEXT = 'ゲームIDの長さが正しくありません。'
  ERROR_REAL_RP_IS_UNINPUTED = '17'
  ERROR_REAL_RP_IS_UNINPUTED_TEXT = '実RPが入力されていません。'
  ERROR_REAL_RP_NOT_NUMERIC = '18'
  ERROR_REAL_RP_NOT_NUMERIC_TEXT = '実RPが正しい数値でありません。'
  # ユーザログイン関係
  ERROR_USERID_IS_UNINPUTED = '21'
  ERROR_USERID_IS_UNINPUTED_TEXT = 'ユーザーIDが指定されていません。'
  ERROR_USERID_IS_UNREGISTERED = '22'
  ERROR_USERID_IS_UNREGISTERED_TEXT = '指定されたユーザーは登録されていません。'
  ERROR_USERID_OR_PASS_IS_WRONG = '23'
  ERROR_USERID_OR_PASS_IS_WRONG_TEXT = 'ユーザーIDかパスワードが間違っています。'
  ERROR_USERID_IS_HIDDEN = '24'
  ERROR_USERID_IS_HIDDEN_TEXT = '指定されたユーザーは非表示の設定になっています。'
  # 曲リスト/スキルリスト関係
  ERROR_MUSIC_IS_UNDECIDED = '51'
  ERROR_MUSIC_IS_UNDECIDED_TEXT = '曲が指定されていません。'
  ERROR_MUSIC_NOT_EXIST = '52'
  ERROR_MUSIC_NOT_EXIST_TEXT = '指定された曲は存在しません。'
  # コースリスト/スキルリスト関係
  ERROR_COURSE_IS_UNDECIDED = '61'
  ERROR_COURSE_IS_UNDECIDED_TEXT = 'コースが指定されていません。'
  ERROR_COURSE_NOT_EXIST = '62'
  ERROR_COURSE_NOT_EXIST_TEXT = '指定されたコースは存在しません。'
  # 日付指定関係
  ERROR_DATE_IS_INVALID = '71'
  ERROR_DATE_IS_INVALID_TEXT = '指定日が正しい日付ではありません。'
  ERROR_DATE_OUT_OF_RANGE = '72'
  ERROR_DATE_OUT_OF_RANGE_TEXT = '指定日が表示できる範囲外です。'
  # イベント関係
  ERROR_EVENT_ID_IS_UNDECIDED = '91'
  ERROR_EVENT_ID_IS_UNDECIDED_TEXT = 'イベントIDが指定されていません。'
  ERROR_EVENT_ID_NOT_EXIST = '92'
  ERROR_EVENT_ID_NOT_EXIST_TEXT = '指定されたイベントIDは存在しません。'
  ERROR_EVENT_SECTION_NOT_EXIST = '93'
  ERROR_EVENT_SECTION_NOT_EXIST_TEXT = '指定されたイベントセクションは存在しません。'
  # スキル編集関係
  ERROR_RP_AND_RATE_NOT_EXIST = '101'
  ERROR_RP_AND_RATE_NOT_EXIST_TEXT = 'RPとクリアレートがどちらも入力されていません。'
  ERROR_RP_NOT_NUMERIC = '102'
  ERROR_RP_NOT_NUMERIC_TEXT = 'RPが正しい数値でありません。'
  ERROR_RP_OUT_OF_RANGE = '103'
  ERROR_RP_OUT_OF_RANGE_TEXT = 'RPの入力が範囲外です。'
  ERROR_RATE_NOT_NUMERIC = '104'
  ERROR_RATE_NOT_NUMERIC_TEXT = 'クリアレートが正しい数値でありません。'
  ERROR_RATE_OUT_OF_RANGE = '105'
  ERROR_RATE_OUT_OF_RANGE_TEXT = 'クリアレートの入力が範囲外です。'
  ERROR_ESY_RP_AND_RATE_NOT_EXIST = "#{MUSIC_DIFF_ESY}#{ERROR_RP_AND_RATE_NOT_EXIST}"
  ERROR_ESY_RP_AND_RATE_NOT_EXIST_TEXT = "#{MUSIC_DIFF_ESY_NAME}譜面の#{ERROR_RP_AND_RATE_NOT_EXIST_TEXT}"
  ERROR_ESY_RP_NOT_NUMERIC = "#{MUSIC_DIFF_ESY}#{ERROR_RP_NOT_NUMERIC}"
  ERROR_ESY_RP_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_ESY_NAME}譜面の#{ERROR_RP_NOT_NUMERIC_TEXT}"
  ERROR_ESY_RP_OUT_OF_RANGE = "#{MUSIC_DIFF_ESY}#{ERROR_RP_OUT_OF_RANGE}"
  ERROR_ESY_RP_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_ESY_NAME}譜面の#{ERROR_RP_OUT_OF_RANGE_TEXT}"
  ERROR_ESY_RATE_NOT_NUMERIC = "#{MUSIC_DIFF_ESY}#{ERROR_RATE_NOT_NUMERIC}"
  ERROR_ESY_RATE_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_ESY_NAME}譜面の#{ERROR_RATE_NOT_NUMERIC_TEXT}"
  ERROR_ESY_RATE_OUT_OF_RANGE = "#{MUSIC_DIFF_ESY}#{ERROR_RATE_OUT_OF_RANGE}"
  ERROR_ESY_RATE_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_ESY_NAME}譜面の#{ERROR_RATE_OUT_OF_RANGE_TEXT}"
  ERROR_STD_RP_AND_RATE_NOT_EXIST = "#{MUSIC_DIFF_STD}#{ERROR_RP_AND_RATE_NOT_EXIST}"
  ERROR_STD_RP_AND_RATE_NOT_EXIST_TEXT = "#{MUSIC_DIFF_STD_NAME}譜面の#{ERROR_RP_AND_RATE_NOT_EXIST_TEXT}"
  ERROR_STD_RP_NOT_NUMERIC = "#{MUSIC_DIFF_STD}#{ERROR_RP_NOT_NUMERIC}"
  ERROR_STD_RP_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_STD_NAME}譜面の#{ERROR_RP_NOT_NUMERIC_TEXT}"
  ERROR_STD_RP_OUT_OF_RANGE = "#{MUSIC_DIFF_STD}#{ERROR_RP_OUT_OF_RANGE}"
  ERROR_STD_RP_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_STD_NAME}譜面の#{ERROR_RP_OUT_OF_RANGE_TEXT}"
  ERROR_STD_RATE_NOT_NUMERIC = "#{MUSIC_DIFF_STD}#{ERROR_RATE_NOT_NUMERIC}"
  ERROR_STD_RATE_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_STD_NAME}譜面の#{ERROR_RATE_NOT_NUMERIC_TEXT}"
  ERROR_STD_RATE_OUT_OF_RANGE = "#{MUSIC_DIFF_STD}#{ERROR_RATE_OUT_OF_RANGE}"
  ERROR_STD_RATE_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_STD_NAME}譜面の#{ERROR_RATE_OUT_OF_RANGE_TEXT}"
  ERROR_HRD_RP_AND_RATE_NOT_EXIST = "#{MUSIC_DIFF_HRD}#{ERROR_RP_AND_RATE_NOT_EXIST}"
  ERROR_HRD_RP_AND_RATE_NOT_EXIST_TEXT = "#{MUSIC_DIFF_HRD_NAME}譜面の#{ERROR_RP_AND_RATE_NOT_EXIST_TEXT}"
  ERROR_HRD_RP_NOT_NUMERIC = "#{MUSIC_DIFF_HRD}#{ERROR_RP_NOT_NUMERIC}"
  ERROR_HRD_RP_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_HRD_NAME}譜面の#{ERROR_RP_NOT_NUMERIC_TEXT}"
  ERROR_HRD_RP_OUT_OF_RANGE = "#{MUSIC_DIFF_HRD}#{ERROR_RP_OUT_OF_RANGE}"
  ERROR_HRD_RP_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_HRD_NAME}譜面の#{ERROR_RP_OUT_OF_RANGE_TEXT}"
  ERROR_HRD_RATE_NOT_NUMERIC = "#{MUSIC_DIFF_HRD}#{ERROR_RATE_NOT_NUMERIC}"
  ERROR_HRD_RATE_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_HRD_NAME}譜面の#{ERROR_RATE_NOT_NUMERIC_TEXT}"
  ERROR_HRD_RATE_OUT_OF_RANGE = "#{MUSIC_DIFF_HRD}#{ERROR_RATE_OUT_OF_RANGE}"
  ERROR_HRD_RATE_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_HRD_NAME}譜面の#{ERROR_RATE_OUT_OF_RANGE_TEXT}"
  ERROR_MAS_RP_AND_RATE_NOT_EXIST = "#{MUSIC_DIFF_MAS}#{ERROR_RP_AND_RATE_NOT_EXIST}"
  ERROR_MAS_RP_AND_RATE_NOT_EXIST_TEXT = "#{MUSIC_DIFF_MAS_NAME}譜面の#{ERROR_RP_AND_RATE_NOT_EXIST_TEXT}"
  ERROR_MAS_RP_NOT_NUMERIC = "#{MUSIC_DIFF_MAS}#{ERROR_RP_NOT_NUMERIC}"
  ERROR_MAS_RP_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_MAS_NAME}譜面の#{ERROR_RP_NOT_NUMERIC_TEXT}"
  ERROR_MAS_RP_OUT_OF_RANGE = "#{MUSIC_DIFF_MAS}#{ERROR_RP_OUT_OF_RANGE}"
  ERROR_MAS_RP_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_MAS_NAME}譜面の#{ERROR_RP_OUT_OF_RANGE_TEXT}"
  ERROR_MAS_RATE_NOT_NUMERIC = "#{MUSIC_DIFF_MAS}#{ERROR_RATE_NOT_NUMERIC}"
  ERROR_MAS_RATE_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_MAS_NAME}譜面の#{ERROR_RATE_NOT_NUMERIC_TEXT}"
  ERROR_MAS_RATE_OUT_OF_RANGE = "#{MUSIC_DIFF_MAS}#{ERROR_RATE_OUT_OF_RANGE}"
  ERROR_MAS_RATE_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_MAS_NAME}譜面の#{ERROR_RATE_OUT_OF_RANGE_TEXT}"
  ERROR_UNL_RP_AND_RATE_NOT_EXIST = "#{MUSIC_DIFF_UNL}#{ERROR_RP_AND_RATE_NOT_EXIST}"
  ERROR_UNL_RP_AND_RATE_NOT_EXIST_TEXT = "#{MUSIC_DIFF_UNL_NAME}譜面の#{ERROR_RP_AND_RATE_NOT_EXIST_TEXT}"
  ERROR_UNL_RP_NOT_NUMERIC = "#{MUSIC_DIFF_UNL}#{ERROR_RP_NOT_NUMERIC}"
  ERROR_UNL_RP_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_UNL_NAME}譜面の#{ERROR_RP_NOT_NUMERIC_TEXT}"
  ERROR_UNL_RP_OUT_OF_RANGE = "#{MUSIC_DIFF_UNL}#{ERROR_RP_OUT_OF_RANGE}"
  ERROR_UNL_RP_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_UNL_NAME}譜面の#{ERROR_RP_OUT_OF_RANGE_TEXT}"
  ERROR_UNL_RATE_NOT_NUMERIC = "#{MUSIC_DIFF_UNL}#{ERROR_RATE_NOT_NUMERIC}"
  ERROR_UNL_RATE_NOT_NUMERIC_TEXT = "#{MUSIC_DIFF_UNL_NAME}譜面の#{ERROR_RATE_NOT_NUMERIC_TEXT}"
  ERROR_UNL_RATE_OUT_OF_RANGE = "#{MUSIC_DIFF_UNL}#{ERROR_RATE_OUT_OF_RANGE}"
  ERROR_UNL_RATE_OUT_OF_RANGE_TEXT = "#{MUSIC_DIFF_UNL_NAME}譜面の#{ERROR_RATE_OUT_OF_RANGE_TEXT}"
  ERRORS = {
    ERROR_SESSION_IS_DEAD            => ERROR_SESSION_IS_DEAD_TEXT,
    ERROR_SESSION_IS_FINISHED        => ERROR_SESSION_IS_FINISHED_TEXT,
    ERROR_INVALID_ACCESS             => ERROR_INVALID_ACCESS_TEXT,
    ERROR_DATABASE_SAVE_FAILED       => ERROR_DATABASE_SAVE_FAILED_TEXT,
    ERROR_USERNAME_IS_UNINPUTED      => ERROR_USERNAME_IS_UNINPUTED_TEXT,
    ERROR_PASSWORD1_IS_UNINPUTED     => ERROR_PASSWORD1_IS_UNINPUTED_TEXT,
    ERROR_PASSWORD2_IS_UNINPUTED     => ERROR_PASSWORD2_IS_UNINPUTED_TEXT,
    ERROR_PASSWORDS_ARE_NOT_EQUAL    => ERROR_PASSWORDS_ARE_NOT_EQUAL_TEXT,
    ERROR_REAL_RP_IS_UNINPUTED       => ERROR_REAL_RP_IS_UNINPUTED_TEXT,
    ERROR_REAL_RP_NOT_NUMERIC        => ERROR_REAL_RP_NOT_NUMERIC_TEXT,
    ERROR_GAME_ID_NOT_NUMERIC        => ERROR_GAME_ID_NOT_NUMERIC_TEXT,
    ERROR_GAME_ID_LENGTH_IS_INVALID  => ERROR_GAME_ID_LENGTH_IS_INVALID_TEXT,
    ERROR_USERID_IS_UNINPUTED        => ERROR_USERID_IS_UNINPUTED_TEXT,
    ERROR_USERID_IS_UNREGISTERED     => ERROR_USERID_IS_UNREGISTERED_TEXT,
    ERROR_USERID_OR_PASS_IS_WRONG    => ERROR_USERID_OR_PASS_IS_WRONG_TEXT,
    ERROR_USERID_IS_HIDDEN           => ERROR_USERID_IS_HIDDEN_TEXT,
    ERROR_MUSIC_IS_UNDECIDED         => ERROR_MUSIC_IS_UNDECIDED_TEXT,
    ERROR_MUSIC_NOT_EXIST            => ERROR_MUSIC_NOT_EXIST_TEXT,
    ERROR_COURSE_IS_UNDECIDED        => ERROR_COURSE_IS_UNDECIDED_TEXT,
    ERROR_COURSE_NOT_EXIST           => ERROR_COURSE_NOT_EXIST_TEXT,
    ERROR_DATE_IS_INVALID            => ERROR_DATE_IS_INVALID_TEXT,
    ERROR_DATE_OUT_OF_RANGE          => ERROR_DATE_OUT_OF_RANGE_TEXT,
    ERROR_EVENT_ID_IS_UNDECIDED      => ERROR_EVENT_ID_IS_UNDECIDED_TEXT,
    ERROR_EVENT_ID_NOT_EXIST         => ERROR_EVENT_ID_NOT_EXIST_TEXT,
    ERROR_EVENT_SECTION_NOT_EXIST    => ERROR_EVENT_SECTION_NOT_EXIST_TEXT,
    ERROR_RP_AND_RATE_NOT_EXIST      => ERROR_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_RP_NOT_NUMERIC             => ERROR_RP_NOT_NUMERIC_TEXT,
    ERROR_RP_OUT_OF_RANGE            => ERROR_RP_OUT_OF_RANGE_TEXT,
    ERROR_RATE_NOT_NUMERIC           => ERROR_RATE_NOT_NUMERIC_TEXT,
    ERROR_RATE_OUT_OF_RANGE          => ERROR_RATE_OUT_OF_RANGE_TEXT,
    ERROR_ESY_RP_AND_RATE_NOT_EXIST  => ERROR_ESY_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_ESY_RP_NOT_NUMERIC         => ERROR_ESY_RP_NOT_NUMERIC_TEXT,
    ERROR_ESY_RP_OUT_OF_RANGE        => ERROR_ESY_RP_OUT_OF_RANGE_TEXT,
    ERROR_ESY_RATE_NOT_NUMERIC       => ERROR_ESY_RATE_NOT_NUMERIC_TEXT,
    ERROR_ESY_RATE_OUT_OF_RANGE      => ERROR_ESY_RATE_OUT_OF_RANGE_TEXT,
    ERROR_STD_RP_AND_RATE_NOT_EXIST  => ERROR_STD_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_STD_RP_NOT_NUMERIC         => ERROR_STD_RP_NOT_NUMERIC_TEXT,
    ERROR_STD_RP_OUT_OF_RANGE        => ERROR_STD_RP_OUT_OF_RANGE_TEXT,
    ERROR_STD_RATE_NOT_NUMERIC       => ERROR_STD_RATE_NOT_NUMERIC_TEXT,
    ERROR_STD_RATE_OUT_OF_RANGE      => ERROR_STD_RATE_OUT_OF_RANGE_TEXT,
    ERROR_HRD_RP_AND_RATE_NOT_EXIST  => ERROR_HRD_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_HRD_RP_NOT_NUMERIC         => ERROR_HRD_RP_NOT_NUMERIC_TEXT,
    ERROR_HRD_RP_OUT_OF_RANGE        => ERROR_HRD_RP_OUT_OF_RANGE_TEXT,
    ERROR_HRD_RATE_NOT_NUMERIC       => ERROR_HRD_RATE_NOT_NUMERIC_TEXT,
    ERROR_HRD_RATE_OUT_OF_RANGE      => ERROR_HRD_RATE_OUT_OF_RANGE_TEXT,
    ERROR_MAS_RP_AND_RATE_NOT_EXIST  => ERROR_MAS_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_MAS_RP_NOT_NUMERIC         => ERROR_MAS_RP_NOT_NUMERIC_TEXT,
    ERROR_MAS_RP_OUT_OF_RANGE        => ERROR_MAS_RP_OUT_OF_RANGE_TEXT,
    ERROR_MAS_RATE_NOT_NUMERIC       => ERROR_MAS_RATE_NOT_NUMERIC_TEXT,
    ERROR_MAS_RATE_OUT_OF_RANGE      => ERROR_MAS_RATE_OUT_OF_RANGE_TEXT,
    ERROR_UNL_RP_AND_RATE_NOT_EXIST  => ERROR_UNL_RP_AND_RATE_NOT_EXIST_TEXT,
    ERROR_UNL_RP_NOT_NUMERIC         => ERROR_UNL_RP_NOT_NUMERIC_TEXT,
    ERROR_UNL_RP_OUT_OF_RANGE        => ERROR_UNL_RP_OUT_OF_RANGE_TEXT,
    ERROR_UNL_RATE_NOT_NUMERIC       => ERROR_UNL_RATE_NOT_NUMERIC_TEXT,
    ERROR_UNL_RATE_OUT_OF_RANGE      => ERROR_UNL_RATE_OUT_OF_RANGE_TEXT,
  }
  SKILL_ERRORS = {
    MUSIC_DIFF_ESY => {
      ERROR_RP_AND_RATE_NOT_EXIST    => ERROR_ESY_RP_AND_RATE_NOT_EXIST_TEXT,
      ERROR_RP_NOT_NUMERIC           => ERROR_ESY_RP_NOT_NUMERIC_TEXT,
      ERROR_RP_OUT_OF_RANGE          => ERROR_ESY_RP_OUT_OF_RANGE_TEXT,
      ERROR_RATE_NOT_NUMERIC         => ERROR_ESY_RATE_NOT_NUMERIC_TEXT,
      ERROR_RATE_OUT_OF_RANGE        => ERROR_ESY_RATE_OUT_OF_RANGE_TEXT,
    },
    MUSIC_DIFF_STD => {
      ERROR_RP_AND_RATE_NOT_EXIST    => ERROR_STD_RP_AND_RATE_NOT_EXIST_TEXT,
      ERROR_RP_NOT_NUMERIC           => ERROR_STD_RP_NOT_NUMERIC_TEXT,
      ERROR_RP_OUT_OF_RANGE          => ERROR_STD_RP_OUT_OF_RANGE_TEXT,
      ERROR_RATE_NOT_NUMERIC         => ERROR_STD_RATE_NOT_NUMERIC_TEXT,
      ERROR_RATE_OUT_OF_RANGE        => ERROR_STD_RATE_OUT_OF_RANGE_TEXT,
    },
    MUSIC_DIFF_HRD => {
      ERROR_RP_AND_RATE_NOT_EXIST    => ERROR_HRD_RP_AND_RATE_NOT_EXIST_TEXT,
      ERROR_RP_NOT_NUMERIC           => ERROR_HRD_RP_NOT_NUMERIC_TEXT,
      ERROR_RP_OUT_OF_RANGE          => ERROR_HRD_RP_OUT_OF_RANGE_TEXT,
      ERROR_RATE_NOT_NUMERIC         => ERROR_HRD_RATE_NOT_NUMERIC_TEXT,
      ERROR_RATE_OUT_OF_RANGE        => ERROR_HRD_RATE_OUT_OF_RANGE_TEXT,
    },
    MUSIC_DIFF_MAS => {
      ERROR_RP_AND_RATE_NOT_EXIST    => ERROR_MAS_RP_AND_RATE_NOT_EXIST_TEXT,
      ERROR_RP_NOT_NUMERIC           => ERROR_MAS_RP_NOT_NUMERIC_TEXT,
      ERROR_RP_OUT_OF_RANGE          => ERROR_MAS_RP_OUT_OF_RANGE_TEXT,
      ERROR_RATE_NOT_NUMERIC         => ERROR_MAS_RATE_NOT_NUMERIC_TEXT,
      ERROR_RATE_OUT_OF_RANGE        => ERROR_MAS_RATE_OUT_OF_RANGE_TEXT,
    },
    MUSIC_DIFF_UNL => {
      ERROR_RP_AND_RATE_NOT_EXIST    => ERROR_UNL_RP_AND_RATE_NOT_EXIST_TEXT,
      ERROR_RP_NOT_NUMERIC           => ERROR_UNL_RP_NOT_NUMERIC_TEXT,
      ERROR_RP_OUT_OF_RANGE          => ERROR_UNL_RP_OUT_OF_RANGE_TEXT,
      ERROR_RATE_NOT_NUMERIC         => ERROR_UNL_RATE_NOT_NUMERIC_TEXT,
      ERROR_RATE_OUT_OF_RANGE        => ERROR_UNL_RATE_OUT_OF_RANGE_TEXT,
    },
  }
end
