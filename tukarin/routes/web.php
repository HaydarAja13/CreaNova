<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('login');
})->name('login');

Route::prefix('admin')->group(function () {
    Route::get('/', function () {
        return view('admin.dashboard');
    })->name('admin.dashboard');

    Route::get('/sampah-point', function () {
        return view('admin.sampah-point');
    })->name('admin.sampah-point');

    Route::get('/transaksi-langsung', function () {
        return view('admin.transaksi-langsung');
    })->name('admin.transaksi-langsung');

    Route::get('/transaksi-jemput', function () {
        return view('admin.transaksi-jemput');
    })->name('admin.transaksi-jemput');

    Route::get('/kurir', function () {
        return view('admin.kurir');
    })->name('admin.kurir');

    Route::get('/laporan', function () {
        return view('admin.laporan');
    })->name('admin.laporan');
});

Route::prefix('superadmin')->group(function () {
    Route::get('/', function () {
        return view('superadmin.dashboard');
    })->name('superadmin.dashboard');

    Route::get('/sampah-point', function () {
        return view('superadmin.sampah-point');
    })->name('superadmin.sampah-point');

    Route::get('/kurir', function () {
        return view('superadmin.kurir');
    })->name('superadmin.kurir');

    Route::get('/laporan', function () {
        return view('superadmin.laporan');
    })->name('superadmin.laporan');

    Route::get('/bank-sampah', function () {
        return view('superadmin.bank-sampah');
    })->name('superadmin.bank-sampah');

    Route::get('/verifikasi', function () {
        return view('superadmin.verifikasi');
    })->name('superadmin.verifikasi');

    Route::get('/nasabah', function () {
        return view('superadmin.nasabah');
    })->name('superadmin.nasabah');

    Route::get('/artikel', function () {
        return view('superadmin.artikel');
    })->name('superadmin.artikel');

    Route::get('/voucher', function () {
        return view('superadmin.voucher');
    })->name('superadmin.voucher');
});
