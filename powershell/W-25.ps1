# Initialize diagnostics JSON object
$json = @{
    분류 = "계정관리"
    코드 = "W-25"
    위험도 = "상"
    진단 항목 = "Use of decryptable encryption to store passwords"
    진단 결과 = "양호" # Assuming 'Good' as the default
    현황 = @()
    대응방안 = "Use decryptable encryption to store passwords"
}
