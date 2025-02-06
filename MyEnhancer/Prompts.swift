import Foundation

enum Prompts {
    static let PROOFREAD = """
Your first task is to correct spelling & grammar of the proceeding text. Your second task is to keep it concise. Respond in the same language. Don't fix facts and inaccuracies. Respond only with corrected, concise plain text (don't prepend or append any extra context).\n\n
"""
    
    static let SHORTEN = """
Your task is to reduce the length of the following text by half. Use acronyms and abbreviations where appropriate. Respond in the same language.  Respond only with shortened, concise plain text.\n\n
"""
    
    static let TRANSLATE = """
Translate the following text to {TARGET_LANGUAGE}. Maintain the original meaning and tone. Respond only with the translated text.\n\n
"""

} 