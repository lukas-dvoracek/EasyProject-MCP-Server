use async_trait::async_trait;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use serde::Deserialize;
use serde_json::{json, Value};
use tracing::{debug, error, info};

use crate::api::EasyProjectClient;
use crate::mcp::protocol::{CallToolResult, ToolResult};
use super::executor::ToolExecutor;

// === GET ATTACHMENT METADATA ===

pub struct GetAttachmentTool {
    api_client: EasyProjectClient,
}

impl GetAttachmentTool {
    pub fn new(api_client: EasyProjectClient, _config: crate::config::AppConfig) -> Self {
        Self { api_client }
    }
}

#[derive(Debug, Deserialize)]
struct GetAttachmentArgs {
    id: i32,
}

#[async_trait]
impl ToolExecutor for GetAttachmentTool {
    fn name(&self) -> &str {
        "get_attachment"
    }

    fn description(&self) -> &str {
        "Získá metadata přílohy (filename, content_type, filesize, content_url) podle ID. Nepodává binární obsah — pro stažení použij download_attachment."
    }

    fn input_schema(&self) -> Value {
        json!({
            "id": {
                "type": "integer",
                "description": "ID přílohy"
            }
        })
    }

    async fn execute(&self, arguments: Option<Value>) -> Result<CallToolResult, Box<dyn std::error::Error + Send + Sync>> {
        let args: GetAttachmentArgs = serde_json::from_value(
            arguments.ok_or("Chybí povinný parametr 'id'")?
        )?;

        debug!("Získávám metadata přílohy ID: {}", args.id);

        match self.api_client.get_attachment(args.id).await {
            Ok(response) => {
                let att_json = serde_json::to_string_pretty(&response.attachment)?;
                info!("Metadata přílohy získána: {}", response.attachment.filename);
                Ok(CallToolResult::success(vec![
                    ToolResult::text(format!("Metadata přílohy:\n\n{}", att_json))
                ]))
            }
            Err(e) => {
                error!("Chyba při získávání přílohy {}: {}", args.id, e);
                Ok(CallToolResult::error(vec![
                    ToolResult::text(format!("Chyba: {}", e))
                ]))
            }
        }
    }
}

// === DOWNLOAD ATTACHMENT BINARY ===

pub struct DownloadAttachmentTool {
    api_client: EasyProjectClient,
}

impl DownloadAttachmentTool {
    pub fn new(api_client: EasyProjectClient, _config: crate::config::AppConfig) -> Self {
        Self { api_client }
    }
}

#[derive(Debug, Deserialize)]
struct DownloadAttachmentArgs {
    id: i32,
    /// Pokud zadáno, uloží binární obsah do souboru a vrátí cestu. Jinak vrátí base64.
    #[serde(default)]
    save_to_path: Option<String>,
}

#[async_trait]
impl ToolExecutor for DownloadAttachmentTool {
    fn name(&self) -> &str {
        "download_attachment"
    }

    fn description(&self) -> &str {
        "Stáhne binární obsah přílohy. \
        Defaultně vrátí jako base64 (vhodné pro obrázky, které Claude může číst pomocí image_url). \
        Pokud zadán 'save_to_path', uloží binár do souboru a vrátí cestu."
    }

    fn input_schema(&self) -> Value {
        json!({
            "id": {
                "type": "integer",
                "description": "ID přílohy"
            },
            "save_to_path": {
                "type": "string",
                "description": "Volitelná absolutní cesta k souboru pro uložení. Pokud chybí, vrátí se base64."
            }
        })
    }

    async fn execute(&self, arguments: Option<Value>) -> Result<CallToolResult, Box<dyn std::error::Error + Send + Sync>> {
        let args: DownloadAttachmentArgs = serde_json::from_value(
            arguments.ok_or("Chybí povinný parametr 'id'")?
        )?;

        debug!("Stahuji přílohu ID: {}", args.id);

        match self.api_client.download_attachment(args.id).await {
            Ok((bytes, filename, content_type)) => {
                let size = bytes.len();
                info!("Příloha stažena: {} ({} bajtů)", filename, size);

                if let Some(path) = args.save_to_path {
                    match std::fs::write(&path, &bytes) {
                        Ok(_) => Ok(CallToolResult::success(vec![
                            ToolResult::text(format!(
                                "Příloha uložena: {}\n  filename: {}\n  size: {} B\n  content_type: {}",
                                path, filename, size, content_type.unwrap_or_else(|| "—".to_string())
                            ))
                        ])),
                        Err(e) => Ok(CallToolResult::error(vec![
                            ToolResult::text(format!("Chyba zápisu '{}': {}", path, e))
                        ]))
                    }
                } else {
                    let b64 = BASE64.encode(&bytes);
                    Ok(CallToolResult::success(vec![
                        ToolResult::text(format!(
                            "Příloha {} ({} B, {}): base64 níže\n\ndata:{};base64,{}",
                            filename, size,
                            content_type.as_deref().unwrap_or("application/octet-stream"),
                            content_type.as_deref().unwrap_or("application/octet-stream"),
                            b64
                        ))
                    ]))
                }
            }
            Err(e) => {
                error!("Chyba při stahování přílohy {}: {}", args.id, e);
                Ok(CallToolResult::error(vec![
                    ToolResult::text(format!("Chyba: {}", e))
                ]))
            }
        }
    }
}
