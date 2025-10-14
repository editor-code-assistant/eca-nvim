---@meta

---@alias eca.ChatModel string
---@alias eca.ChatBehavior 'agent'|'plan'
---@class eca.ServerCapabilities
---@field welcomeMessage string
---@field models eca.ChatModel[]
---@field defaultModel eca.ChatModel
---@field behaviors eca.ChatBehavior[]
---@field defaultBehavior eca.ChatBehavior

---@class eca.ChatContext
---@field type string
---@field path? string
---@field linesRange? {start: integer, end: integer}
---@field url? string
---@field uri? string
---@field name? string
---@field description? string
---@field mimeType? string
---@field server? string

---@class eca.ChatCommand
---@field name string
---@field description string
---@field help string
---@field type "mcp-prompt"|"native"
---@field arguments {name: string, description?: string, required: boolean}[]

---@alias eca.ToolCallOrigin "mcp"|"native"

---@alias eca.ToolCallDetails eca.FileChangedDetails

---TODO: flesh these out
---@alias eca.MessageParams table
---@alias eca.Message table

---@class eca.FileChangedDetails
---@field type 'fileChange'
---@field path string the file path of this file change
---@field diff string the content diff of this file change
---@field linesAdded integer the count of lines added in this change
---@field linesRemoved integer the count of lines removed in this change

---@class eca.ToolCallPrepare
---@field type 'toolCallPrepare'
---@field origin eca.ToolCallOrigin
---@field id string the id of the tool call
---@field name string name of the tool
---@field argumentsText {[string]: string} arguments of the tool call
---@field manualApproval boolean whether the call requires manual approval from the user
---@field summary string  summary text to present about this tool call
--- extra details for the call. clients may use this to present a different UX
--- for this tool call.
---@field details eca.ToolCallDetails
---

---@class eca.ToolCallRun
---@field type 'toolCallRun'
---@field origin eca.ToolCallOrigin
---@field id string the id of the tool call
---@field name string name of the tool
---@field arguments {[string]: string} arguments of the tool call
---@field manualApproval boolean whether the call requires manual approval from the user
---@field summary string  summary text to present about this tool call
--- extra details for the call. clients may use this to present a different UX
--- for this tool call.
---@field details eca.ToolCallDetails

---@class eca.ToolCalled
---@field type 'toolCalled'
---@field id string the id of the tool call
---@field name string name of the tool
---@field arguments {[string]: string} arguments of the tool call
---@field errors boolean was there an error calling the tool
---@field outputs {type: 'text', text: string}[] the result of the tool call
---@field summary? string summary text to present about the tool call
---@field details? eca.ToolCallDetails extra details about the call

---@class eca.UsageContent
---@field type 'usage'
---@field messageInputTokens number
---@field messageOutputTokens number
---@field sessionTokens number
---@field messageCost? string
---@field sessionCost? string

---@class eca.ContextCursor
---@field path string
---@field position { position_start: { line: number , character: number }, position_end: { line: number , character: number } }

---@class eca.ContextDirectory
---@field path string

---@class eca.ContextFile
---@field path string
---@field lines_range { line_start: number, line_end: number }

---@class eca.ContextWeb
---@field path string

---@class eca.Context
---@field type 'cursor'|'directory'|'file'|'web'
---@field data eca.ContextCursor|eca.ContextDirectory|eca.ContextFile|eca.ContextWeb
