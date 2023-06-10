# debian
Debian服务器维护脚本

```markdown
要复制的文本： [点击复制](javascript:void(0))

<script src="https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/2.0.8/clipboard.min.js"></script>
<script>
  var textToCopy = 'wget --no-check-certificate -O debian-maintained.sh https://raw.githubusercontent.com/cautious1064/debian/main/%E5%A4%9A%E5%8A%9F%E8%83%BD%E8%84%9A%E6%9C%AC.sh && chmod a+x debian-maintained.sh && bash debian-maintained.sh';

  function copyTextToClipboard(text) {
    var tempInput = document.createElement('textarea');
    tempInput.value = text;
    document.body.appendChild(tempInput);
    tempInput.select();
    document.execCommand('copy');
    document.body.removeChild(tempInput);
  }

  var copyButton = document.querySelector('.copy-button');
  copyButton.addEventListener('click', function() {
    copyTextToClipboard(textToCopy);
  });
</script>
