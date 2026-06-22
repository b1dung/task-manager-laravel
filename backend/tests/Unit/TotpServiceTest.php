<?php

namespace Tests\Unit;

use App\Services\TotpService;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

class TotpServiceTest extends TestCase
{
    #[Test]
    public function it_matches_the_rfc_6238_sha1_vector_and_accepts_the_adjacent_window(): void
    {
        $totp = new TotpService;
        $secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

        $this->assertSame('287082', $totp->code($secret, 59));
        $this->assertTrue($totp->verify($secret, '287082', 59));
        $this->assertTrue($totp->verify($secret, '287082', 89));
        $this->assertFalse($totp->verify($secret, '287082', 119));
        $this->assertFalse($totp->verify($secret, '12345', 59));
    }
}
