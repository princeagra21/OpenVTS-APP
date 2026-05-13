import 'package:dio/dio.dart';
import 'package:open_vts/core/database/app_database.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/storage/secure_storage.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/data/mappers/auth_mapper.dart';
import 'package:open_vts/features/auth/data/models/auth_request_dtos.dart';
import 'package:open_vts/features/auth/data/models/login_request.dart';
import 'package:open_vts/features/auth/data/models/refresh_token_response_dto.dart';
import 'package:open_vts/features/auth/data/sources/auth_retrofit_service.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRetrofitService api,
    required SecureStorage storage,
    required AuthMapper mapper,
    AppDatabase? cacheDatabase,
  })  : _api = api,
        _storage = storage,
        _mapper = mapper,
        _cacheDatabase = cacheDatabase;

  final AuthRetrofitService _api;
  final SecureStorage _storage;
  final AuthMapper _mapper;
  final AppDatabase? _cacheDatabase;

  @override
  Future<Result<LoginResponse, AppError>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final raw = await _api.login(
        LoginRequest(identifier: identifier, password: password),
      );

      final dtoResult = _mapper.loginDtoFromRaw(raw);
      if (dtoResult.isFailure) {
        await _storage.clearAll();
        return Result.failure(dtoResult.errorOrNull!);
      }

      final dto = dtoResult.valueOrNull!;
      final responseResult = _mapper.loginResponseFromDto(dto);
      if (responseResult.isFailure) {
        await _storage.clearAll();
        return Result.failure(responseResult.errorOrNull!);
      }

      await _storage.saveTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      );
      return responseResult;
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AuthUser?, AppError>> restoreSession() async {
    try {
      final token = (await _storage.getAccessToken())?.trim();
      if (token == null || token.isEmpty) {
        return const Result.success(null);
      }

      final refreshToken = await _storage.getRefreshToken();
      final session = _mapper.sessionFromToken(token, refreshToken: refreshToken);
      final userResult = _mapper.userFromSession(session);
      if (userResult.isFailure) {
        await _storage.clearAll();
        return const Result.success(null);
      }

      return Result.success(userResult.valueOrNull);
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AuthUser?, AppError>> refreshSession() async {
    try {
      final refreshToken = (await _storage.getRefreshToken())?.trim();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearAll();
        return const Result.success(null);
      }

      final raw = await _api.refreshToken(RefreshTokenRequestDto(refreshToken: refreshToken));
      final dto = RefreshTokenResponseDto.fromRaw(raw);
      await _storage.saveTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken ?? refreshToken,
      );

      final session = _mapper.sessionFromToken(
        dto.accessToken,
        refreshToken: dto.refreshToken ?? refreshToken,
      );
      final userResult = _mapper.userFromSession(session);
      if (userResult.isFailure) {
        await _storage.clearAll();
        return Result.failure(userResult.errorOrNull!);
      }

      return Result.success(userResult.valueOrNull);
    } on DioException catch (error) {
      await _storage.clearAll();
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      await _storage.clearAll();
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<String, AppError>> forgotPassword({required String identifier}) async {
    try {
      final raw = await _api.forgotPassword(ForgotPasswordRequestDto(identifier: identifier));
      return Result.success(_mapper.forgotPasswordMessage(raw));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> logout() async {
    try {
      await _storage.clearAll();
      await _cacheDatabase?.clearAllCachedData();
      return const Result.success(null);
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }
}
