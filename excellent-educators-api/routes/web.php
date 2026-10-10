<?php

use App\Http\Controllers\GoogleOAuthController;
use App\Http\Controllers\StudentPhotoController;
use App\Http\Controllers\TeacherPhotoController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::options('/media/teachers/{file}', [TeacherPhotoController::class, 'options']);
Route::get('/media/teachers/{file}', [TeacherPhotoController::class, 'show'])
    ->name('teacher.photo')
    ->middleware('signed');

Route::options('/media/students/{file}', [StudentPhotoController::class, 'options']);
Route::get('/media/students/{file}', [StudentPhotoController::class, 'show'])
    ->name('student.photo')
    ->middleware('signed');

Route::get('/auth/google/redirect', [GoogleOAuthController::class, 'redirect'])->name('google.redirect');
Route::get('/auth/google/callback', [GoogleOAuthController::class, 'callback'])->name('google.callback');
