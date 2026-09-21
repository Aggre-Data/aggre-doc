# Aggre REST 範例集

每個 `requests/*.json` 都是可獨立送到 `POST /v1/mcp/call` 的完整 body；不含金鑰。
在 Git Bash、WSL、macOS 或 Linux 的 `sh` 執行單一範例：

```sh
export AGGRE_API_KEY='<your-key>'
sh examples/fetch-aggre.sh --request examples/requests/01-retrieve-labor-notice.json
```

執行全部公開讀取範例：

```sh
sh examples/invoke-all-examples.sh
```

| 工具 | 請求檔 | 說明 |
|---|---|---|
| `retrieve` | [01-retrieve-labor-notice.json](requests/01-retrieve-labor-notice.json) | 法規語意檢索 |
| `retrieve_batch` | [02-retrieve-batch-labor.json](requests/02-retrieve-batch-labor.json) | 多題檢索 |
| `search_judgments` | [03-search-judgments-unjust-enrichment.json](requests/03-search-judgments-unjust-enrichment.json) | 判決理由段落 |
| `get_judgment` | [04-get-judgment.json](requests/04-get-judgment.json) | 讀取判決上下文 |
| `lookup_judgment` | [05-lookup-judgment.json](requests/05-lookup-judgment.json) | 用字號驗證判決 |
| `get_record` | [06-get-record-labor-act-16.json](requests/06-get-record-labor-act-16.json) | 取回原始記錄 |
| `list_datasets` | [07-list-legal-datasets.json](requests/07-list-legal-datasets.json) | 發現特定法律資料集 |
| `search_dataset` | [08-search-dataset-laws.json](requests/08-search-dataset-laws.json) | 法規字面搜尋 |
| `get_dataset_schema` | [09-get-dataset-schema.json](requests/09-get-dataset-schema.json) | 讀取 schema |

`responses/retrieve-labor-notice.json` 是真實、去除認證資訊的回應摘錄。其他請求的結果請以 runner 當下取得的資料為準，避免把會變動的資料集內容誤當固定測試資料。

兩支 shell script 會回傳 REST envelope（`{ "name": "…", "result": { … } }`）。若有 `jq`，可只看結果：

```sh
sh examples/fetch-aggre.sh --request examples/requests/01-retrieve-labor-notice.json | jq '.result'
```
