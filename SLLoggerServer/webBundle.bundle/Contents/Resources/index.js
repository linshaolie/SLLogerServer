
var placeholders = [
                    ['lld', 'llu'],
                    ['ld', 'lf', 'Lf', 'li', 'hi', 'hu', 'qi', 'qu', 'qx', 'qX', 'zu'],
                    ['@', 'd', 'D', 'i', 'u', 'U', 'f', 'F', 'x', 'X', 'o', 'O',
                     'e', 'E', 'g', 'G', 'c', 'C', 's', 'S', 'L', 'p', 'a', 'A',
                     'z', 't', 'j', '%']
                    ];

function init() {
    var refreshDelay = 500;
    var footerElement = null;
    var contentElm = null;
    var needOutput = true;
    var continuousFailedCount = 0;  //连续请求失败次数
    var logs = [];
//    var allLog = '';
    var filteredLogs = [];
    var isFilter = false;
    
    function updateTimestamp() {
        var now = new Date();
        footerElement.innerHTML = 'Last updated on ' + now.toLocaleDateString() + ' ' + now.toLocaleTimeString();
    }
    function refresh() {
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState == 4) {
                if (xmlhttp.status == 200) {
                    continuousFailedCount = 0;
                    if (xmlhttp.responseText) {
                        try {
                            
                            var newElm = document.createElement('ul');
                            var content = xmlhttp.responseText.replace(/\n/g, '<br>').replace(/ /g, '&nbsp;');
                            var reg = /^[1-9]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])&nbsp;+(20|21|22|23|[0-1]\d):[0-5]\d:[0-5]\d.*\+0800/;
                            var matchs = content.match(reg);
                            if (matchs) {
                                var idx = matchs[0].length;
                            }
                            if (idx !== -1) {
                                content = '<b style="color: #0019ff;">' + content.substring(0, idx) + '</b>' + content.substring(idx);
                            }
                            newElm.innerHTML = content;
                            logs.push(newElm.outerHTML);
                            if (isFilter) {
                                if (!needFilter(content)) {
                                    filteredLogs.push(newElm.outerHTML);
                                    contentElm.appendChild(newElm);
                                }
                            } else {
                                contentElm.appendChild(newElm);
                            }
                            window.scrollTo(0,document.body.scrollHeight)
                            
                            var rst = JSON.parse(xmlhttp.responseText);
                            rst = build(rst);
                            var str = 'console.log(';
                            for (var i = 0; i < rst.length; i++) {
                                str += `rst[${i}],`;
                            }
                            str += ')';
                            eval(str);
                        } catch(err) {
                            console.log(xmlhttp.responseText);
                        }
                    }
                } else {
                    if (continuousFailedCount++ >= 2) {
                        needOutput = false;
                    }
                    footerElement.innerHTML = '<span class="error">Connection failed! Reload page to try again.</span>';
                }
                updateTimestamp();
                if (needOutput) {
                    setTimeout(refresh, refreshDelay);
                }
            }
        }
        xmlhttp.open("GET", "/log", true);
        xmlhttp.send();
    }
    
    function build(contents) {
        var format = contents.shift();

        format = format.replace('%%', 'åß∂');
        var results = [];
        var pIdx = format.indexOf('%');
        while(pIdx !== -1) {
            var sub = format.substr(0, pIdx);
            sub = sub.replace('åß∂', '%');
            results.push(sub);
            format = format.substr(pIdx);

            var finded = false;
            for (var l = 4; l > 1; l--) {
                var f = format.substr(0, l);
                var pArr = placeholders[4 - l];

                for (var j = 0; j < pArr.length; j++) {
                    var placeholder = '%' + pArr[j];

                    if (f == placeholder) {
                        results.push(contents.shift());
                        format = format.substr(l);
                        finded = true;
                    }
                }

                if (finded) {
                    break;
                }
            }

            if (!finded) {
                results.pop();
                results.push(sub + '%');
                format = format.substr(1);
            }

            pIdx = format.indexOf('%');
        }

        if (format) {
            format = format.replace('åß∂', '%');
            results.push(format);
        }

        return results;
    }

    window.onload = function() {
        footerElement = document.getElementById("footer");
        contentElm = document.getElementById("content");
        
        updateTimestamp();
        setTimeout(refresh, refreshDelay);
        
        document.getElementById("startLogs").onclick = startLogs;
        document.getElementById("stopLogs").onclick = stopLogs;
        document.getElementById("clearLogs").onclick = clearLogs;
        document.getElementById("filterLogs").onclick = filterLogs;
    }
    
    function render() {
        if (isFilter) {
            contentElm.innerHTML = filteredLogs.join('');
        } else {
            contentElm.innerHTML = allLog;
        }
    }

    function stopLogs() {
        needOutput = false;
    }
    
    function startLogs() {
        if (needOutput == false) {
            needOutput = true;
            setTimeout(refresh, refreshDelay);
        }
    }
    
    function clearLogs() {
        contentElm.innerHTML = "";
        allLog = '';
        logs = [];
        filteredLogs = [];
    }
    
    function filterLogs() {
        var result = [];
        var value = document.getElementById("filterFiled").value;
        if (value) {
            isFilter = true;
            for (var i = 0; i < logs.length; i++) {
                if (!needFilter(logs[i])) {
                    result.push(logs[i]);
                }
            }
            filteredLogs = result;
            allLog = logs.join('');
        } else {
            isFilter = false;
        }
        render();
    }
    
    function needFilter(str) {
        var value = document.getElementById("filterFiled").value;
        if (value && isFilter) {
            if (str.indexOf(value) !== -1) {
                return false;
            }
        }
        return true;
    }
}


init();
