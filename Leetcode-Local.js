// ==UserScript==
// @name         Leetcode-Local
// @namespace    http://tampermonkey.net/
// @version      0.2
// @description  Copy question's id, English name, description and code template to system clipboard
// @author       iCrystal
// @match        https://leetcode-cn.com/problems/*
// @grant        none
// ==/UserScript==


(function() {
    'use strict';

    var count = 0;

    // 在题目名称后面：添加一个按钮
    function addCopyButton() {
        console.log('ok');
        var idTag = document.getElementsByTagName('h4')[0];
        if (idTag == null) {
            if (count++ > 10) { return; }
            setTimeout(function(){addCopyButton();}, 1000);
            return;
        }

        // 添加按钮
        var button = document.createElement('input');
        button.setAttribute('type', 'button');
        button.setAttribute('value', 'Copy');
        button.style.width = "60px";
        button.style.align = "left"
        button.style.backgroundColor = "#b46300";
        button.style.color = "white";
        idTag.appendChild(button);

        // 点击按钮的事件
        button.onclick = function(){
            // 题目id
            var idTag = document.getElementsByTagName('h4')[0].innerText;
            var id = idTag.substr(0, idTag.indexOf('.'));

            // 题目英文名称
            var titleEn = document.URL.substr(33);
            var len = titleEn.length;
            if (titleEn[len-1] == '/') {
                titleEn = titleEn.substr(0, len-1);
            }
            var title = id + '.' + titleEn;

            // Description
            var description = document.getElementsByClassName('notranslate')[1].innerText;

            // 默认模板代码
            var inputTags = document.getElementsByTagName('input');
            var codeTemplate = inputTags.namedItem('code').getAttribute('value');

            // 复制到系统剪贴板
            var textarea = document.createElement('textarea');
            textarea.value = title + "\n" + description + "\n" + codeTemplate;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand("Copy");
            textarea.className = "textarea";
            textarea.style.display = "none";
            button.setAttribute('value', 'OK');
            setTimeout(function(){ button.setAttribute('value', 'Copy'); }, 3000);
        } // end function: button.onclick

    } // end function: addCopyButton

    addCopyButton();

})();
