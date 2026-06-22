<?php

namespace App\Services;

class TotpService
{
    private const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    public function secret(): string
    {
        return $this->base32Encode(random_bytes(20));
    }

    public function verify(string $secret, string $code, ?int $timestamp = null): bool
    {
        if (! preg_match('/^\d{6}$/', $code)) {
            return false;
        }
        $counter = intdiv($timestamp ?? time(), 30);
        foreach ([-1, 0, 1] as $window) {
            if (hash_equals($this->codeAt($secret, $counter + $window), $code)) {
                return true;
            }
        }

        return false;
    }

    public function code(string $secret, ?int $timestamp = null): string
    {
        return $this->codeAt($secret, intdiv($timestamp ?? time(), 30));
    }

    private function codeAt(string $secret, int $counter): string
    {
        $binary = pack('N2', ($counter >> 32) & 0xFFFFFFFF, $counter & 0xFFFFFFFF);
        $digest = hash_hmac('sha1', $binary, $this->base32Decode($secret), true);
        $offset = ord($digest[19]) & 0x0F;
        $value = unpack('N', substr($digest, $offset, 4))[1] & 0x7FFFFFFF;

        return str_pad((string) ($value % 1000000), 6, '0', STR_PAD_LEFT);
    }

    private function base32Encode(string $input): string
    {
        $bits = '';
        foreach (unpack('C*', $input) as $byte) {
            $bits .= str_pad(decbin($byte), 8, '0', STR_PAD_LEFT);
        }
        $out = '';
        for ($i = 0; $i < strlen($bits); $i += 5) {
            $out .= self::ALPHABET[bindec(str_pad(substr($bits, $i, 5), 5, '0'))];
        }

        return $out;
    }

    private function base32Decode(string $input): string
    {
        $bits = '';
        foreach (str_split(strtoupper(rtrim($input, '='))) as $char) {
            $value = strpos(self::ALPHABET, $char);
            if ($value === false) {
                throw new \InvalidArgumentException('Invalid base32 secret');
            }
            $bits .= str_pad(decbin($value), 5, '0', STR_PAD_LEFT);
        }
        $out = '';
        for ($i = 0; $i + 8 <= strlen($bits); $i += 8) {
            $out .= chr(bindec(substr($bits, $i, 8)));
        }

        return $out;
    }
}
