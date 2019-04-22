// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';

/// The context for reading or writing tokens.
///
/// Tokens cannot be compared, so tokens for [indexOfToken] must be previously
/// received from [tokenOfIndex], or the context must be created from a
/// [TokensResult] (the result of writing previously parsed tokens).
class TokensContext {
  final UnlinkedTokens _tokens;
  final List<Token> _indexToToken;
  final Map<Token, int> _tokenToIndex;

  TokensContext(this._tokens)
      : _indexToToken = List<Token>(_tokens.type.length),
        _tokenToIndex = Map.identity();

  TokensContext.fromResult(
      this._tokens, this._indexToToken, this._tokenToIndex);

  /// TODO(scheglov) Not used yet, maybe remove.
  int addSyntheticToken(
      UnlinkedTokenKind kind, UnlinkedTokenType type, String lexeme) {
    var index = _tokens.kind.length;
    UnlinkedTokensBuilder tokens = _tokens;
    tokens.kind.add(kind);
    tokens.lexeme.add(lexeme);
    tokens.offset.add(0);
    tokens.length.add(0);
    tokens.type.add(type);
    tokens.next.add(0);
    tokens.endGroup.add(0);
    tokens.precedingComment.add(0);
    tokens.isSynthetic.add(true);
    return index;
  }

  int indexOfToken(Token token) {
    if (token == null) return 0;

    var index = _tokenToIndex[token];
    if (index == null) {
      throw StateError('Unexpected token: $token');
    }
    return index;
  }

  String lexeme(int index) {
    return _tokens.lexeme[index];
  }

  void linkTokens(Token from, Token to) {
    var fromIndex = _tokenToIndex[from];
    var toIndex = _tokenToIndex[to];
    Token prevToken = null;
    for (var index = fromIndex; index <= toIndex && index != 0;) {
      var token = _indexToToken[index];
      token ??= tokenOfIndex(index);

      prevToken?.next = token;

      prevToken = token;
      index = _tokens.next[index];
    }
  }

  int offset(int index) {
    return _tokens.offset[index];
  }

  Token tokenOfIndex(int index) {
    if (index == 0) return null;

    var token = _indexToToken[index];
    if (token == null) {
      var kind = _tokens.kind[index];
      switch (kind) {
        case UnlinkedTokenKind.nothing:
          return null;
        case UnlinkedTokenKind.comment:
          token = CommentToken(
            _binaryToAstTokenType(_tokens.type[index]),
            _tokens.lexeme[index],
            _tokens.offset[index],
          );
          break;
        case UnlinkedTokenKind.keyword:
          token = KeywordToken(
            _binaryToAstTokenType(_tokens.type[index]),
            _tokens.offset[index],
            _getCommentToken(_tokens.precedingComment[index]),
          );
          break;
        case UnlinkedTokenKind.simple:
          token = SimpleToken(
            _binaryToAstTokenType(_tokens.type[index]),
            _tokens.offset[index],
            _getCommentToken(_tokens.precedingComment[index]),
          );
          break;
        case UnlinkedTokenKind.string:
          token = StringToken(
            _binaryToAstTokenType(_tokens.type[index]),
            _tokens.lexeme[index],
            _tokens.offset[index],
            _getCommentToken(_tokens.precedingComment[index]),
          );
          break;
        default:
          throw UnimplementedError('Token kind: $kind');
      }
      _indexToToken[index] = token;
      _tokenToIndex[token] = index;
    }
    return token;
  }

  UnlinkedTokenType type(int index) {
    return _tokens.type[index];
  }

  CommentToken _getCommentToken(int index) {
    var result = tokenOfIndex(index);
    var token = result;
    while (true) {
      index = _tokens.next[index];
      if (index == 0) return result;

      var nextToken = tokenOfIndex(index);
      token.next = nextToken;
      token = nextToken;
    }
  }

  static TokenType _binaryToAstTokenType(UnlinkedTokenType type) {
    switch (type) {
      case UnlinkedTokenType.ABSTRACT:
        return Keyword.ABSTRACT;
      case UnlinkedTokenType.AMPERSAND:
        return TokenType.AMPERSAND;
      case UnlinkedTokenType.AMPERSAND_AMPERSAND:
        return TokenType.AMPERSAND_AMPERSAND;
      case UnlinkedTokenType.AMPERSAND_EQ:
        return TokenType.AMPERSAND_EQ;
      case UnlinkedTokenType.AS:
        return TokenType.AS;
      case UnlinkedTokenType.ASSERT:
        return Keyword.ASSERT;
      case UnlinkedTokenType.ASYNC:
        return Keyword.ASYNC;
      case UnlinkedTokenType.AT:
        return TokenType.AT;
      case UnlinkedTokenType.AWAIT:
        return Keyword.AWAIT;
      case UnlinkedTokenType.BACKPING:
        return TokenType.BACKPING;
      case UnlinkedTokenType.BACKSLASH:
        return TokenType.BACKSLASH;
      case UnlinkedTokenType.BANG:
        return TokenType.BANG;
      case UnlinkedTokenType.BANG_EQ:
        return TokenType.BANG_EQ;
      case UnlinkedTokenType.BAR:
        return TokenType.BAR;
      case UnlinkedTokenType.BAR_BAR:
        return TokenType.BAR_BAR;
      case UnlinkedTokenType.BAR_EQ:
        return TokenType.BAR_EQ;
      case UnlinkedTokenType.BREAK:
        return Keyword.BREAK;
      case UnlinkedTokenType.CARET:
        return TokenType.CARET;
      case UnlinkedTokenType.CARET_EQ:
        return TokenType.CARET_EQ;
      case UnlinkedTokenType.CASE:
        return Keyword.CASE;
      case UnlinkedTokenType.CATCH:
        return Keyword.CATCH;
      case UnlinkedTokenType.CLASS:
        return Keyword.CLASS;
      case UnlinkedTokenType.CLOSE_CURLY_BRACKET:
        return TokenType.CLOSE_CURLY_BRACKET;
      case UnlinkedTokenType.CLOSE_PAREN:
        return TokenType.CLOSE_PAREN;
      case UnlinkedTokenType.CLOSE_SQUARE_BRACKET:
        return TokenType.CLOSE_SQUARE_BRACKET;
      case UnlinkedTokenType.COLON:
        return TokenType.COLON;
      case UnlinkedTokenType.COMMA:
        return TokenType.COMMA;
      case UnlinkedTokenType.CONST:
        return Keyword.CONST;
      case UnlinkedTokenType.CONTINUE:
        return Keyword.CONTINUE;
      case UnlinkedTokenType.COVARIANT:
        return Keyword.COVARIANT;
      case UnlinkedTokenType.DEFAULT:
        return Keyword.DEFAULT;
      case UnlinkedTokenType.DEFERRED:
        return Keyword.DEFERRED;
      case UnlinkedTokenType.DO:
        return Keyword.DO;
      case UnlinkedTokenType.DOUBLE:
        return TokenType.DOUBLE;
      case UnlinkedTokenType.DYNAMIC:
        return Keyword.DYNAMIC;
      case UnlinkedTokenType.ELSE:
        return Keyword.ELSE;
      case UnlinkedTokenType.ENUM:
        return Keyword.ENUM;
      case UnlinkedTokenType.EOF:
        return TokenType.EOF;
      case UnlinkedTokenType.EQ:
        return TokenType.EQ;
      case UnlinkedTokenType.EQ_EQ:
        return TokenType.EQ_EQ;
      case UnlinkedTokenType.EXPORT:
        return Keyword.EXPORT;
      case UnlinkedTokenType.EXTENDS:
        return Keyword.EXTENDS;
      case UnlinkedTokenType.EXTERNAL:
        return Keyword.EXTERNAL;
      case UnlinkedTokenType.FACTORY:
        return Keyword.FACTORY;
      case UnlinkedTokenType.FALSE:
        return Keyword.FALSE;
      case UnlinkedTokenType.FINAL:
        return Keyword.FINAL;
      case UnlinkedTokenType.FINALLY:
        return Keyword.FINALLY;
      case UnlinkedTokenType.FOR:
        return Keyword.FOR;
      case UnlinkedTokenType.FUNCTION:
        return TokenType.FUNCTION;
      case UnlinkedTokenType.FUNCTION_KEYWORD:
        return Keyword.FUNCTION;
      case UnlinkedTokenType.GET:
        return Keyword.GET;
      case UnlinkedTokenType.GT:
        return TokenType.GT;
      case UnlinkedTokenType.GT_EQ:
        return TokenType.GT_EQ;
      case UnlinkedTokenType.GT_GT:
        return TokenType.GT_GT;
      case UnlinkedTokenType.GT_GT_EQ:
        return TokenType.GT_GT_EQ;
      case UnlinkedTokenType.GT_GT_GT:
        return TokenType.GT_GT_GT;
      case UnlinkedTokenType.GT_GT_GT_EQ:
        return TokenType.GT_GT_GT_EQ;
      case UnlinkedTokenType.HASH:
        return TokenType.HASH;
      case UnlinkedTokenType.HEXADECIMAL:
        return TokenType.HEXADECIMAL;
      case UnlinkedTokenType.HIDE:
        return Keyword.HIDE;
      case UnlinkedTokenType.IDENTIFIER:
        return TokenType.IDENTIFIER;
      case UnlinkedTokenType.IF:
        return Keyword.IF;
      case UnlinkedTokenType.IMPLEMENTS:
        return Keyword.IMPLEMENTS;
      case UnlinkedTokenType.IMPORT:
        return Keyword.IMPORT;
      case UnlinkedTokenType.IN:
        return Keyword.IN;
      case UnlinkedTokenType.INDEX:
        return TokenType.INDEX;
      case UnlinkedTokenType.INDEX_EQ:
        return TokenType.INDEX_EQ;
      case UnlinkedTokenType.INT:
        return TokenType.INT;
      case UnlinkedTokenType.INTERFACE:
        return Keyword.INTERFACE;
      case UnlinkedTokenType.IS:
        return TokenType.IS;
      case UnlinkedTokenType.LATE:
        return Keyword.LATE;
      case UnlinkedTokenType.LIBRARY:
        return Keyword.LIBRARY;
      case UnlinkedTokenType.LT:
        return TokenType.LT;
      case UnlinkedTokenType.LT_EQ:
        return TokenType.LT_EQ;
      case UnlinkedTokenType.LT_LT:
        return TokenType.LT_LT;
      case UnlinkedTokenType.LT_LT_EQ:
        return TokenType.LT_LT_EQ;
      case UnlinkedTokenType.MINUS:
        return TokenType.MINUS;
      case UnlinkedTokenType.MINUS_EQ:
        return TokenType.MINUS_EQ;
      case UnlinkedTokenType.MINUS_MINUS:
        return TokenType.MINUS_MINUS;
      case UnlinkedTokenType.MIXIN:
        return Keyword.MIXIN;
      case UnlinkedTokenType.MULTI_LINE_COMMENT:
        return TokenType.MULTI_LINE_COMMENT;
      case UnlinkedTokenType.NATIVE:
        return Keyword.NATIVE;
      case UnlinkedTokenType.NEW:
        return Keyword.NEW;
      case UnlinkedTokenType.NULL:
        return Keyword.NULL;
      case UnlinkedTokenType.OF:
        return Keyword.OF;
      case UnlinkedTokenType.ON:
        return Keyword.ON;
      case UnlinkedTokenType.OPEN_CURLY_BRACKET:
        return TokenType.OPEN_CURLY_BRACKET;
      case UnlinkedTokenType.OPEN_PAREN:
        return TokenType.OPEN_PAREN;
      case UnlinkedTokenType.OPEN_SQUARE_BRACKET:
        return TokenType.OPEN_SQUARE_BRACKET;
      case UnlinkedTokenType.OPERATOR:
        return Keyword.OPERATOR;
      case UnlinkedTokenType.PART:
        return Keyword.PART;
      case UnlinkedTokenType.PATCH:
        return Keyword.PATCH;
      case UnlinkedTokenType.PERCENT:
        return TokenType.PERCENT;
      case UnlinkedTokenType.PERCENT_EQ:
        return TokenType.PERCENT_EQ;
      case UnlinkedTokenType.PERIOD:
        return TokenType.PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD:
        return TokenType.PERIOD_PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD_PERIOD:
        return TokenType.PERIOD_PERIOD_PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD_PERIOD_QUESTION:
        return TokenType.PERIOD_PERIOD_PERIOD_QUESTION;
      case UnlinkedTokenType.PLUS:
        return TokenType.PLUS;
      case UnlinkedTokenType.PLUS_EQ:
        return TokenType.PLUS_EQ;
      case UnlinkedTokenType.PLUS_PLUS:
        return TokenType.PLUS_PLUS;
      case UnlinkedTokenType.QUESTION:
        return TokenType.QUESTION;
      case UnlinkedTokenType.QUESTION_PERIOD:
        return TokenType.QUESTION_PERIOD;
      case UnlinkedTokenType.QUESTION_QUESTION:
        return TokenType.QUESTION_QUESTION;
      case UnlinkedTokenType.QUESTION_QUESTION_EQ:
        return TokenType.QUESTION_QUESTION_EQ;
      case UnlinkedTokenType.REQUIRED:
        return Keyword.REQUIRED;
      case UnlinkedTokenType.RETHROW:
        return Keyword.RETHROW;
      case UnlinkedTokenType.RETURN:
        return Keyword.RETURN;
      case UnlinkedTokenType.SCRIPT_TAG:
        return TokenType.SCRIPT_TAG;
      case UnlinkedTokenType.SEMICOLON:
        return TokenType.SEMICOLON;
      case UnlinkedTokenType.SET:
        return Keyword.SET;
      case UnlinkedTokenType.SHOW:
        return Keyword.SHOW;
      case UnlinkedTokenType.SINGLE_LINE_COMMENT:
        return TokenType.SINGLE_LINE_COMMENT;
      case UnlinkedTokenType.SLASH:
        return TokenType.SLASH;
      case UnlinkedTokenType.SLASH_EQ:
        return TokenType.SLASH_EQ;
      case UnlinkedTokenType.SOURCE:
        return Keyword.SOURCE;
      case UnlinkedTokenType.STAR:
        return TokenType.STAR;
      case UnlinkedTokenType.STAR_EQ:
        return TokenType.STAR_EQ;
      case UnlinkedTokenType.STATIC:
        return Keyword.STATIC;
      case UnlinkedTokenType.STRING:
        return TokenType.STRING;
      case UnlinkedTokenType.STRING_INTERPOLATION_EXPRESSION:
        return TokenType.STRING_INTERPOLATION_EXPRESSION;
      case UnlinkedTokenType.STRING_INTERPOLATION_IDENTIFIER:
        return TokenType.STRING_INTERPOLATION_IDENTIFIER;
      case UnlinkedTokenType.SUPER:
        return Keyword.SUPER;
      case UnlinkedTokenType.SWITCH:
        return Keyword.SWITCH;
      case UnlinkedTokenType.SYNC:
        return Keyword.SYNC;
      case UnlinkedTokenType.THIS:
        return Keyword.THIS;
      case UnlinkedTokenType.THROW:
        return Keyword.THROW;
      case UnlinkedTokenType.TILDE:
        return TokenType.TILDE;
      case UnlinkedTokenType.TILDE_SLASH:
        return TokenType.TILDE_SLASH;
      case UnlinkedTokenType.TILDE_SLASH_EQ:
        return TokenType.TILDE_SLASH_EQ;
      case UnlinkedTokenType.TRUE:
        return Keyword.TRUE;
      case UnlinkedTokenType.TRY:
        return Keyword.TRY;
      case UnlinkedTokenType.TYPEDEF:
        return Keyword.TYPEDEF;
      case UnlinkedTokenType.VAR:
        return Keyword.VAR;
      case UnlinkedTokenType.VOID:
        return Keyword.VOID;
      case UnlinkedTokenType.WHILE:
        return Keyword.WHILE;
      case UnlinkedTokenType.WITH:
        return Keyword.WITH;
      case UnlinkedTokenType.YIELD:
        return Keyword.YIELD;
      default:
        throw StateError('Unexpected type: $type');
    }
  }
}
