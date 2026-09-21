# Aggre 法律查詢 API — 請求與回應範例

所有工具都走同一個端點。以下每一節給一個可直接複製的請求，與它實際回傳的形狀。

## 連線

```bash
curl -X POST https://aggre.orbbit.ai/v1/mcp/call \
  -H "x-aggre-api-key: aggre_sk_..." \
  -H "Content-Type: application/json" \
  -d '{"name":"retrieve","arguments":{"query":"民法第184條","corpus":"laws","law_name":"民法","article_no":"184"}}'
```

認證擇一，兩者都接受：`x-aggre-api-key: <key>` 或 `Authorization: Bearer <key>`；
兩個都送時以 `x-aggre-api-key` 為準。

請求 body 只有兩個欄位，`arguments` 可省略（預設 `{}`）：

```json
{ "name": "工具名稱", "arguments": { } }
```

回應 body 也只有兩個欄位：

```json
{ "name": "工具名稱", "result": { } }
```

錯誤是一個扁平物件，HTTP 狀態碼對應 400／401／403／404／409／429／502／500：

```json
{ "error": "API key is missing required scope: SearchRead" }
```

**下面各節的「回應」都是 `result` 的內容**，省略外層 `{"name":…,"result":…}`。

用 MCP client 連線的話：執行 `aggre-mcp`，設 `AGGRE_API_BASE=https://aggre.orbbit.ai`
與 `AGGRE_API_KEY`，其餘由 `tools/list` 自動探索。

---

## 可執行範例與實測回應

完整範例索引在 [`examples/README.md`](examples/README.md)：每個工具各有一份原始 JSON
請求檔、用途說明，以及一次跑完所有讀取案例的 runner。快速以 HTTP Client 互動時，仍可使用
[`examples/requests.http`](examples/requests.http)。請在工具的**私有環境**設定 `AGGRE_API_KEY`，
不要把金鑰填進檔案。

在 Git Bash、WSL、macOS 或 Linux，以 `sh` 從目前程序的環境變數讀取金鑰：

```sh
export AGGRE_API_KEY='<your-key>'
sh examples/fetch-aggre.sh --request examples/requests/01-retrieve-labor-notice.json
sh examples/invoke-all-examples.sh
```

`examples/responses/retrieve-labor-notice.json` 是 2026-09-21 的實測回應摘錄，對應
「雇主終止勞動契約預告期間」的法規檢索；為易讀省略了空陣列欄位，且不含任何認證資訊。實際執行時請以最新回應為準。

| 工具 | 對應範例 |
|---|---|
| `retrieve` / `retrieve_batch` | [`01`](examples/requests/01-retrieve-labor-notice.json) / [`02`](examples/requests/02-retrieve-batch-labor.json) |
| `search_judgments` / `get_judgment` / `lookup_judgment` | [`03`](examples/requests/03-search-judgments-unjust-enrichment.json) / [`04`](examples/requests/04-get-judgment.json) / [`05`](examples/requests/05-lookup-judgment.json) |
| `get_record` / `list_datasets` / `search_dataset` / `get_dataset_schema` | [`06`](examples/requests/06-get-record-labor-act-16.json) / [`07`](examples/requests/07-list-legal-datasets.json) / [`08`](examples/requests/08-search-dataset-laws.json) / [`09`](examples/requests/09-get-dataset-schema.json) |

---

## 1. `retrieve` — 語意檢索

### 1a. 一般語意查詢

請求：

```json
{ "name": "retrieve",
  "arguments": {
    "query": "公務員收賄罪的量刑",
    "corpus": "both",
    "jurisdiction": "TW",
    "depth": "standard",
    "top_k": 5
  } }
```

回應：

```json
{
  "query": "公務員收賄罪的量刑",
  "corpus": "both",
  "searched": ["taiwan-moj-laws-ch-law", "taiwan-moj-orders-ch-order", "taiwan-judgments"],
  "pcode": [],
  "timed_out": [],
  "strategy": "two-stage",
  "tuning": {
    "depth": "standard",
    "candidates": 18,
    "thresholds": {
      "taiwan-moj-laws-ch-law": 0.30,
      "taiwan-moj-orders-ch-order": 0.30,
      "taiwan-judgments": 0.30
    },
    "rerank_chars": 256
  },
  "total": 5,
  "results": [
    {
      "record_id": "3f0ac2f1-…",
      "external_id": "ch-law:C0000001:art:122",
      "dataset": "taiwan-moj-laws-ch-law",
      "title": "中華民國刑法",
      "law_name": "中華民國刑法",
      "pcode": "C0000001",
      "article_no": "第 122 條",
      "court": null,
      "date": null,
      "case_number": null,
      "status": "in-force",
      "effective_note": null,
      "abandon_note": null,
      "article_version_id": null,
      "valid_from": null,
      "valid_to": null,
      "current_as_of": null,
      "rerank_score": 0.97,
      "lexical_score": 0.4127,
      "dense_score": 0.81,
      "endpoint": null,
      "snippet": "公務員或仲裁人對於違背職務之行為，要求、期約或收受賄賂或其他不正利益者…",
      "snippet_truncated": false,
      "content_sha256": "787d0d826db71e03",
      "content_chars": 118
    }
  ]
}
```

每個欄位一定存在，不適用時是 `null`。判決命中改為 `court`／`date`／`case_number` 有值，
`law_name`／`pcode`／`article_no`／`status` 為 `null`。

`snippet` 上限 500 字，`snippet_truncated` 告訴你有沒有被切。要引用原文請用
`record_id` 呼叫 `get_record`。

### 1b. 條號精確查詢

請求：

```json
{ "name": "retrieve",
  "arguments": {
    "query": "民法第184條",
    "corpus": "laws",
    "law_name": "民法",
    "article_no": "184",
    "top_k": 8
  } }
```

回應：

```json
{
  "query": "民法第184條",
  "corpus": "laws",
  "law_name": "民法",
  "article_no": "184",
  "searched": ["taiwan-moj-laws-ch-law"],
  "strategy": "exact",
  "complete": true,
  "as_of": null,
  "as_of_unavailable": [],
  "exact_lookup_unavailable": [],
  "timed_out": [],
  "truncated": false,
  "total": 1,
  "results": [
    {
      "record_id": "…",
      "external_id": "ch-law:B0000001:art:184",
      "dataset": "taiwan-moj-laws-ch-law",
      "law_name": "民法",
      "pcode": "B0000001",
      "article_no": "第 184 條",
      "status": "in-force",
      "current_as_of": null,
      "rerank_score": null,
      "lexical_score": null,
      "snippet": "因故意或過失，不法侵害他人之權利者，負損害賠償責任。故意以背於善良風俗之方法，加損害於他人者亦同。…",
      "snippet_truncated": false,
      "equivalent_record_ids": ["…", "…"],
      "equivalent_external_ids": ["ch-law:B0000001:art:184", "ch-law:B0000001:176"]
    }
  ]
}
```

`strategy` 是 `exact`，回完整條文（不截斷），沒有相似度分數。
`article_no` 可寫 `184`、`184-1`、`第184條之1`。法名精確比對，只會自動忽略開頭的「中華民國」。
內容相同的重複條文會合併，來源識別碼保留在 `equivalent_*`。

**限台灣法規語料**：`laws`、`medical-laws`，或 `dataset` 指定
`taiwan-moj-laws-ch-law`／`taiwan-moj-orders-ch-order`／`taiwan-medical-laws`。
用在判決或其他語料回 400。

### 1c. 限定在某幾部法裡面找

請求：

```json
{ "name": "retrieve",
  "arguments": {
    "query": "發票人簽發一定金額的要件",
    "corpus": "laws",
    "pcode": ["G0380050"],
    "top_k": 8
  } }
```

`pcode` 在召回階段就套用，所以 `top_k` 仍是「這幾部法裡面的 top_k 筆」，最多 16 個。
每筆命中都帶自己的 `pcode`，可直接餵回下一次查詢。

把法名寫進 `query` 沒有用：只有條文本文會被比對。

### 1d. 可用的 `corpus`

| 值 | 內容 |
|---|---|
| `laws` | 法律與命令（`jurisdiction` 可切 TW／CN） |
| `judgments` | 判決（預設） |
| `both` | 法規＋判決合併排序 |
| `rulings` | 財政部各稅法令函釋（僅台灣，忽略 `jurisdiction`） |
| `medical` / `medical-laws` / `medical-judgments` | 醫療切片；`jurisdiction:US` 為 21/42/45 CFR |
| `drug-labels` | openFDA 藥品仿單全文 |
| `fda-safety` | openFDA 回收／執法報告 |
| `sec-filings` | SEC EDGAR 生技申報文件段落 |
| `510k` / `device-summaries` / `device-classification` | FDA 醫材 |

`rulings` 命中的欄位對應：`law_name` = 稅目、`article_no` = 條號（阿拉伯數字）、
`case_number` = 發文字號（如 財政部69/01/09台財稅第30216號函）、`source_url` = 來源連結。
**函釋是行政機關的見解，不是法律，授權條款要求標示來源。**

### 1e. 其他參數

| 參數 | 範圍 | 預設 |
|---|---|---|
| `top_k` | 1–30 | 8 |
| `depth` | `fast` / `standard` / `thorough` | `standard` |
| `candidates` | 10–32 | 依 depth |
| `threshold` | 0.05–0.9 | 依語料 |
| `rerank_chars` | 64–1024 | 依 depth |
| `stage1_timeout_secs` | 3–120 | 依語料 |
| `explain` | bool | false |
| `as_of` | `YYYY-MM-DD` | — |

`explain: true` 會多一個 `diagnostics`，列出實際跑的召回探針、各語料候選數，
以及完整重排池與 `admitted` 旗標——這是唯一能分辨「沒被召回」與「召回了但被擠掉」的方法。

### 1f. `as_of` 目前會 fail closed

請求：

```json
{ "name": "retrieve",
  "arguments": { "query": "民法第184條", "corpus": "laws",
                 "law_name": "民法", "article_no": "184", "as_of": "2019-06-01" } }
```

回應：

```json
{
  "strategy": "as-of-unavailable",
  "complete": false,
  "as_of": "2019-06-01",
  "as_of_unavailable": ["taiwan-moj-laws-ch-law"],
  "total": 0,
  "results": []
}
```

台灣法規語料尚未提供條文版本視窗，帶 `as_of` 一律以此形狀回覆，
**不會用今天的條文冒充當時的條文**。不帶 `as_of` 時 `current_as_of` 是 `null`
（代表未經查核），請改看 `status`。

---

## 2. `retrieve_batch` — 1–3 題併成一次請求

請求：

```json
{ "name": "retrieve_batch",
  "arguments": {
    "queries": [
      { "id": "q1", "query": "雇主不得預告勞工終止勞動契約" },
      { "id": "q2", "query": "終止勞動契約預告期間" }
    ],
    "dataset": "taiwan-moj-laws-ch-law",
    "top_k": 8,
    "cache_control": { "mode": "corpus-version", "namespace": "my-app-v1", "ttl_seconds": 900 }
  } }
```

回應：

```json
{
  "results": [
    {
      "id": "q1",
      "ok": true,
      "result": { "strategy": "two-stage", "total": 8, "results": [ "…" ] },
      "cache": { "status": "miss", "stored": true, "age_seconds": 0 },
      "elapsed_ms": 1840
    },
    {
      "id": "q2",
      "ok": true,
      "result": { "strategy": "two-stage", "total": 8, "results": [ "…" ] },
      "cache": { "status": "hit", "age_seconds": 62 },
      "elapsed_ms": 0
    }
  ],
  "complete": true,
  "batch": {
    "wall_ms": 1902,
    "prelude_ms": 14,
    "setup_ms": 21,
    "batch_work_ms": 1861,
    "compute_ms": 1840,
    "query_count": 2,
    "cache_hits": 1,
    "deadline_ms": 185000
  }
}
```

- 每個 `results[i].result` 就是一次完整的 `retrieve` 回應。
- 查詢彼此獨立：**不串接、rerank 分數不跨題比較**，回應保持輸入順序。
- 單題失敗不影響其他題，該題變成 `{"id":…, "ok":false, "error":{…}}`。
- 共用參數與 `retrieve` 相同（`corpus`／`dataset`／`pcode`／`law_name`／`article_no`／
  `top_k`／`depth`／`as_of`／`explain`）。
- `cache_control.mode` 預設 `no-store`。`corpus-version` 只快取完整成功的結果，
  上限 900 秒，以呼叫端組織隔離。
- 計費按有效子查詢數，不打折。

---

## 3. `search_judgments` — 判決理由段落檢索

`retrieve` 打判決只比對每份判決的前 1,000 字（案由與主文），
問「法院怎麼認定某爭點」要用這個工具。

### 3a. 基本查詢

請求：

```json
{ "name": "search_judgments",
  "arguments": {
    "query": "相當於租金之不當得利 請求權時效",
    "max_results": 5,
    "depth": "standard"
  } }
```

回應：

```json
{
  "results": [
    {
      "doc_id": "CHDV,98,重訴,24,20090714,1",
      "citation_text": "臺灣彰化地方法院98年度重訴字第24號民事判決",
      "court": "臺灣彰化地方法院",
      "court_level": "district",
      "case_type": "民事",
      "doc_type": "判決",
      "case_number": "98年度重訴字第24號",
      "decision_date": "20090714",
      "source": "opendata_fileset",
      "record_id": "…",
      "score": 21.4,
      "rerank_score": 0.88,
      "url": "https://judgment.judicial.gov.tw/FJUD/data.aspx?ty=JD&id=CHDV%2C98%2C…",
      "case": { "status": "final", "final_doc_id": "CHDV,98,重訴,24,20090714,1", "documents": 3 },
      "hits": [
        {
          "passage_id": "…",
          "role": "court_reasoning",
          "certifiable_as_court": true,
          "heading": "理由",
          "start": 1720,
          "end": 2210,
          "excerpt": "按租金之請求權因五年間不行使而消滅…",
          "excerpt_start": 1760,
          "excerpt_end": 2060,
          "score": 21.4
        }
      ]
    }
  ],
  "terms": ["不當得利", "相當於租金", "時效"],
  "complete": true,
  "took_ms": 38,
  "search_ms": 412,
  "strategy": "passage-bm25+rerank",
  "depth": "standard",
  "reranked": true,
  "rerank_pool": 150,
  "collapsed": 2,
  "grouped_by": "case_lineage",
  "note": "只列出最相關的段落；…"
}
```

`start`／`end`／`excerpt_start`／`excerpt_end` 都是 **Unicode code point** 位移，
與 `get_judgment` 的分頁同一單位。`excerpt` 是原文逐字。

`certifiable_as_court` 是從段落所在部分推得的提示，**引用法院見解前請先讀原文**。

**一案一筆**：同一案件在各審級的裁判與同號裁定會合併，`collapsed` 是被合併掉的筆數，
`case.status` 說明目前這一筆在案件中的位置：

| `case.status` | 意思 |
|---|---|
| `final` | 本件是這個案件目前最後的裁判 |
| `affirmed` | 經上級審或再審維持 |
| `reversed` | 已被上級審廢棄，引用前請讀上級審 |
| `remanded` | 已被廢棄發回，另有後續裁判 |
| `reviewed` | 經上級審審理，結果請讀上級審 |

### 3b. `depth` — 重排池深度

| `depth` | 行為 | 時間預算 |
|---|---|---|
| `fast` | 不重排，BM25 原序 | — |
| `standard`（預設） | BM25 前 **150** 筆進 cross-encoder 重排 | 10 秒 |
| `thorough` | BM25 前 **320** 筆 | 25 秒 |

池子越深，不相關的結果越少。25 題盲評中，前五名的 125 個位置裡不相關的數量：
不重排 40、前 30 → 24、前 100 → 21、前 320 → 16。`standard` 是日常用，
`thorough` 用在答案比等待重要的時候。

重排失敗或超出預算時結果仍會送出，改為 BM25 原序，並帶
`"reranked": false`、`"rerank_error": "…"`，`note` 會寫明。

### 3c. 全部參數

| 參數 | 型別 | 預設 | 說明 |
|---|---|---|---|
| `query` | string | — | ≤500 字，繁體中文；至少兩個中文字或一個英文詞。帶 `cites_judgment` 時可省略 |
| `max_results` | int | 5 | 1–10，單位是**判決**，每筆最多三個段落 |
| `depth` | string | `standard` | 見上 |
| `court_level` | string/array | 全部 | `supreme`／`high`／`district` |
| `case_type` | string/array | 全部 | `民事`／`刑事`／`行政`／`家事`／`懲戒`／`其他` |
| `roles` | string/array | 全部 | `court_reasoning`／`mixed_facts_and_reasoning`／`mixed`／`holding` |
| `date_from` `date_to` | `YYYY-MM-DD` | — | 裁判日期，含端點 |
| `synonyms` | bool | true | 口語補法定用語（押金→押租金、加班費→延長工作時間之工資） |
| `excerpt_chars` | int | 300 | 80–600 |
| `cites_article` | string/array | — | 只留理由中引用該條文的判決 |
| `cites_judgment` | string/array | — | 只留引用該判決的判決 |

### 3d. 查「引用某條文的判決」

請求：

```json
{ "name": "search_judgments",
  "arguments": {
    "query": "受僱人執行職務不法侵害他人權利 僱用人連帶責任",
    "cites_article": ["民法第188條"],
    "court_level": ["supreme"],
    "max_results": 5
  } }
```

`cites_article` 寫法：「民法第184條」「勞基法第11條第5款」「土地法第34條之1」，
可給一個或一個陣列。寫不出條文格式會回 400。

### 3e. 查「引用某判決的判決」

不給 `query` 時直接列舉引用者，最高法院優先、新的在前：

```json
{ "name": "search_judgments",
  "arguments": { "cites_judgment": ["最高法院110年度台上字第1432號"], "max_results": 10 } }
```

回應的 `depth` 會是 `"citing"`，`reranked` 為 `false`。

字號必須能判定法院（字號自帶法院、可解析的 JID、或字別以「台」開頭視為最高法院），
否則回 400：同一個年度字號在很多法院都存在。

### 3f. 注意

- 支付命令、本票裁定、補繳裁判費這類程序裁定**不在索引內**。查無不代表沒有判決。
- 部分 MCP client 會依 `tools/list` 廣告的 schema 過濾參數，可能擋掉
  `depth`／`cites_article`／`cites_judgment`。改用 `POST /v1/mcp/call` 直接送即可。
- 判決索引未啟用的部署會回 400：
  `the judgment passage index is not enabled on this deployment; use retrieve with corpus=judgments`。

---

## 4. `get_judgment` — 分頁讀整份判決

請求：

```json
{ "name": "get_judgment",
  "arguments": { "doc_id": "CHDV,98,重訴,24,20090714,1", "around": 1760, "max_chars": 3000 } }
```

回應：

```json
{
  "doc_id": "CHDV,98,重訴,24,20090714,1",
  "citation_text": "臺灣彰化地方法院98年度重訴字第24號民事判決",
  "court": "臺灣彰化地方法院",
  "court_level": "district",
  "case_type": "民事",
  "case_number": "98年度重訴字第24號",
  "decision_date": "20090714",
  "text": "…主文…事實及理由…",
  "offset": 1010,
  "next_offset": 4010,
  "total_chars": 8842,
  "truncated": true,
  "content_sha256": "…",
  "segmenter_version": "v4",
  "sections": [
    { "role": "court_reasoning", "certifiable_as_court": true, "start": 1120, "end": 3900 }
  ],
  "cited_articles": [
    { "law": "民法", "article": "126" },
    { "law": "民法", "article": "179" }
  ],
  "cited_judgments": ["最高法院49年台上字第1730號"],
  "case_history": {
    "available": true,
    "case": "…",
    "upper": [ { "doc_id": "…", "citation_text": "臺灣高等法院臺中分院99年度上字第…號民事判決" } ],
    "lower": [],
    "same_case": [ "…" ],
    "built_at": "2026-09-18",
    "note": "審級歷程依各裁判主文前所載的原審裁判比對而得，每日更新；…"
  }
}
```

| 參數 | 型別 | 預設 | 說明 |
|---|---|---|---|
| `doc_id` | string | — | `search_judgments`／`lookup_judgment` 回的 JID |
| `offset` | int | 0 | 起始 code point，傳上一頁的 `next_offset` |
| `around` | int | — | 從這個 code point 往前四分之一頁開始（例如某 hit 的 `excerpt_start`）。不可與 `offset` 併用 |
| `max_chars` | int | 3000 | 200–20,000 |

**只有 `next_offset` 為 `null` 時才算讀完整份判決。** 第15條之1 寫成 `"article": "15-1"`。
`case_history` 沒有 `upper` 不代表已確定，最新的上訴可能尚未公開。
JID 不在索引回 404。

---

## 5. `lookup_judgment` — 用字號驗證判決存在

請求：

```json
{ "name": "lookup_judgment", "arguments": { "citation": "最高法院49年台上字第1730號" } }
```

回應：

```json
{
  "normalized": { "year": "49", "word": "台上", "number": "1730", "court": "最高法院" },
  "matches": [
    {
      "doc_id": "TPSV,49,台上,1730,19601231,1",
      "citation_text": "最高法院49年度台上字第1730號民事判決",
      "court": "最高法院",
      "court_level": "supreme",
      "case_type": "民事",
      "case_number": "49年度台上字第1730號",
      "decision_date": "19601231"
    }
  ],
  "ambiguous": false,
  "other_courts": [],
  "note": "…"
}
```

`citation` 接受「最高法院49年台上字第1730號」「113 年度 臺上 字第 1234 號」、
中文數字、或 JID，≤200 字。字號沒寫法院時可另給 `court`。

- 法院比對寬鬆（台北地院 = 臺灣臺北地方法院）但**不跨審級**。
- 同一法院同一年度字號同時有民事與刑事案時 `ambiguous: true`，可在 citation 寫明
  「…民事判決」指定。
- 指定的法院查無、但別的法院有時，`other_courts` 會列出來。
- **查無不代表該判決不存在**：索引只收司法院開放資料與判決 API 的實體裁判。

---

## 6. `get_record` — 取原始全文

`retrieve` 的 `snippet` 只供排序與顯示，引用前用 `record_id` 取完整記錄。

請求：

```json
{ "name": "get_record", "arguments": { "id": "3f0ac2f1-…" } }
```

回應（就是記錄本身，沒有外層包裝）：

```json
{
  "id": "3f0ac2f1-…",
  "dataset_id": "…",
  "source_id": "…",
  "version": 1,
  "external_id": "ch-law:C0000001:art:122",
  "data_hash": "…",
  "data": { "name": "中華民國刑法", "article_no": "第 122 條", "content": "公務員或仲裁人…" },
  "created_at": "2026-07-28T…"
}
```

`external_id` 是上游的穩定鍵，引用時請以它為準。

---

## 7. `list_datasets` — 有哪些資料集

請求：

```json
{ "name": "list_datasets", "arguments": { "category": "legal", "tags": ["jurisdiction:TW", "rag:retrievable"] } }
```

回應：

```json
{
  "datasets": [
    {
      "id": "…",
      "slug": "taiwan-judgments",
      "name": "…",
      "description": "…",
      "category": "legal",
      "tags": ["jurisdiction:TW", "lang:zh-Hant", "type:case-law", "modality:fulltext", "rag:retrievable"],
      "schema": { },
      "status": "active",
      "version": 1,
      "record_count": 88919,
      "created_at": "…",
      "updated_at": "…"
    }
  ],
  "total": 1,
  "facets": {
    "jurisdiction": ["TW"],
    "lang": ["zh-Hant"],
    "type": ["case-law", "statute"],
    "modality": ["fulltext"],
    "rag": ["retrievable"]
  }
}
```

`category` 可為 `legal`／`healthcare`／`markets`；`tags` 是 AND，全部要命中；
`query` 對 slug／name／description 做子字串比對。
**請讀回應的 `facets` 來知道目前實際有哪些 facet 值**，不要假設。

---

## 8. `search_dataset` — 單一資料集的字串比對

請求：

```json
{ "name": "search_dataset", "arguments": { "dataset_id": "taiwan-judgments", "query": "不當得利", "limit": 5 } }
```

回應：

```json
{
  "results": [
    { "id": "…", "dataset_id": "…", "source_id": "…", "version": 1,
      "external_id": "…", "data_hash": "…",
      "data": { "…": "…" },
      "created_at": "…", "score": 1.0 }
  ],
  "total": 1
}
```

這是**字面子字串比對**，大小寫不分，而且比對的是整段序列化的 `data` JSON，
包含欄位名稱——查 `"ticker"` 會命中所有有 `ticker` 欄位的記錄。
概念性的問題請用 `retrieve`。`dataset_id` 接受 UUID 或 slug，`limit` 1–50（預設 10）。

`total` 是這一頁的筆數，不是全庫命中總數。

---

## 9. `get_dataset_schema` — 欄位與敏感標註

請求：

```json
{ "name": "get_dataset_schema", "arguments": { "dataset_id": "taiwan-judgments" } }
```

回應：

```json
{
  "id": "…",
  "slug": "taiwan-judgments",
  "name": "…",
  "status": "active",
  "version": 1,
  "schema": {
    "type": "object",
    "properties": {
      "court": { "type": "string" },
      "case_number": { "type": "string" },
      "judgment_date": { "type": "string" },
      "content": { "type": "string" }
    }
  }
}
```

被遮罩的欄位會帶 `"x-aggre-sensitive": true`。

---

## 10. 典型流程

**問法條** → `retrieve`（`corpus:"laws"`）→ 取 `record_id` → `get_record` 讀全文 →
以 `law_name` + `article_no` + `external_id` 引用。

**已知條號** → `retrieve` 帶 `law_name` + `article_no`，一次到位。

**問法院見解** → `search_judgments` → 取 `doc_id` 與 hit 的 `excerpt_start` →
`get_judgment` 帶 `around` 讀上下文 → 看 `case.status` 確認沒被上級審廢棄。

**驗證對造引用的判決** → `lookup_judgment` 帶字號 → 有 `matches` 再用
`get_judgment` 讀內容。

**查某條文的實務見解** → `search_judgments` 帶 `cites_article`。

**追某個指標判決的後續** → `search_judgments` 帶 `cites_judgment`（不給 `query`）。

---

## 11. 逾時建議

第一階段每個語料各有自己的預算，客戶端 timeout 請留足：

| 情境 | `standard` | `thorough` |
|---|---|---|
| `corpus:"both"`／TW（3 個語料） | ≥150 秒 | ≥210 秒 |
| 單獨 `taiwan-judgments` | ≥110 秒 | ≥155 秒 |
| `search_judgments` | 約 2 秒 | 約 3 秒 |
| `retrieve_batch` | 整批硬上限 185 秒 | 同 |

用 Python 呼叫時請設一個真實的 User-Agent；預設的 `python-requests/…` 會先被 WAF 擋下。

---

## 12. 回應中一定要看的旗標

| 欄位 | 意思 |
|---|---|
| `complete: false` | 這次回答不完整，不要當成完整結果 |
| `searched` | 實際查了哪些資料集；`corpus` 只是把你送的值原樣回傳 |
| `timed_out` | 哪些語料的第一階段超出預算 |
| `strategy` | `two-stage`／`exact`／`as-of-unavailable`／`lexical-fallback`／`timeout-degraded` |
| `status`（每筆） | `in-force`／`repealed`／`not-yet-effective`／`not-in-force`／`partially-deferred`／`unknown` |
| `not_in_force`（頂層） | 有命中已廢止或尚未施行的條文時出現，`note` 會以 `NOT CURRENT LAW:` 開頭 |
| `snippet_truncated` | snippet 是否被 500 字上限切斷 |
| `current_as_of` | `null` 代表未經時點查核，不等於「今天有效」 |
| `reranked`（判決） | `false` 代表結果是 BM25 原序 |
| `case.status`（判決） | `reversed`／`remanded` 表示引用前要先讀上級審 |

行政命令語料有相當比例是已廢止的條文，`corpus:"laws"` 同時涵蓋法律與命令，
**請對每一筆命中檢查 `status`**。
