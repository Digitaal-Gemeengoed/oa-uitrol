<#--
  Opmaak van alle inlogpagina's in de stijl van de OA-panelen: dezelfde kop
  (icoon, titel, korte uitleg), Utrecht-componenten en het voorbeeldthema.
  De pagina's zelf (login.ftl, login-update-password.ftl, error.ftl, ...)
  komen ongewijzigd uit het basisthema; wat die nodig hebben (de secties
  header, show-username, form, socialProviders en info, en de scripts van
  Keycloak) blijft hier gelijk aan base/login/template.ftl.
-->
<#import "footer.ftl" as loginFooter>
<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html>
<html class="${properties.kcHtmlClass!}" lang="${lang}"<#if realm.internationalizationEnabled> dir="${(locale.rtl)?then('rtl','ltr')}"</#if>>
<head>
    <meta charset="utf-8">
    <#if properties.meta?has_content>
        <#list properties.meta?split(' ') as meta>
            <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
        </#list>
    </#if>
    <title>${msg("loginTitle")}</title>
    <link rel="icon" type="image/svg+xml" href="${url.resourcesPath}/img/oa.svg" />
    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <#if properties.scripts?has_content>
        <#list properties.scripts?split(' ') as script>
            <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <script type="importmap">
        {
            "imports": {
                "rfc4648": "${url.resourcesCommonPath}/vendor/rfc4648/rfc4648.js"
            }
        }
    </script>
    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <script type="module">
        <#outputformat "JavaScript">
        import { startSessionPolling } from ${(url.resourcesPath + "/js/authChecker.js")?c};
        startSessionPolling(${url.ssoLoginInOtherTabsUrl?c});
        </#outputformat>
    </script>
    <script type="module">
        document.addEventListener("click", (event) => {
            const link = event.target.closest("a[data-once-link]");
            if (!link) return;
            if (link.getAttribute("aria-disabled") === "true") { event.preventDefault(); return; }
            const { disabledClass } = link.dataset;
            if (disabledClass) link.classList.add(...disabledClass.trim().split(/\s+/));
            link.setAttribute("role", "link");
            link.setAttribute("aria-disabled", "true");
        });
    </script>
    <#if authenticationSession??>
        <script type="module">
            <#outputformat "JavaScript">
            import { checkAuthSession } from ${(url.resourcesPath + "/js/authChecker.js")?c};
            checkAuthSession(${authenticationSession.authSessionIdHash?c});
            </#outputformat>
        </script>
    </#if>
</head>

<body class="${properties.kcBodyClass!} ${bodyClass}" data-page-id="login-${pageId}">
<div class="${properties.kcLoginClass!}">
  <main class="${properties.kcFormCardClass!}">
    <header class="oa-kop">
        <span class="oa-kop-icoon" aria-hidden="true">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/><circle cx="12" cy="15.5" r="1.5"/></svg>
        </span>
        <div>
            <p class="oa-merk">${msg("oaTitel")}</p>
            <#if !(auth?has_content && auth.showUsername() && !auth.showResetCredentials())>
                <h1 id="kc-page-title" class="utrecht-heading-2"><#nested "header"></h1>
                <#if pageId == "login.ftl"><p class="utrecht-paragraph utrecht-paragraph--small oa-onder">${msg("oaOnder")}</p></#if>
            <#else>
                <#nested "show-username">
                <h1 id="kc-page-title" class="utrecht-heading-2"><#nested "header"></h1>
                <p id="kc-username" class="utrecht-paragraph utrecht-paragraph--small oa-onder">
                    <span id="kc-attempted-username">${auth.attemptedUsername}</span>
                    · <a id="reset-login" class="utrecht-link" href="${url.loginRestartFlowUrl}">${msg("restartLoginTooltip")}</a>
                </p>
            </#if>
        </div>
    </header>

    <#if displayRequiredFields>
        <p class="utrecht-paragraph utrecht-paragraph--small oa-verplicht"><span class="required">*</span> ${msg("requiredFields")}</p>
    </#if>

    <div id="kc-content">
        <#-- Meldingen; een app-gestarte actie krijgt geen waarschuwing over die actie zelf. -->
        <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
            <#assign soort = (message.type == 'success')?then('ok', message.type)>
            <div class="${properties.kcAlertClass!} utrecht-alert--${soort} alert-${message.type}" role="<#if message.type == 'error'>alert<#else>status</#if>">
                <div class="utrecht-alert__content">
                    <p class="${properties.kcAlertTitleClass!} utrecht-paragraph kc-feedback-text">${kcSanitize(message.summary)?no_esc}</p>
                </div>
            </div>
        </#if>

        <#nested "form">

        <#if auth?has_content && auth.showTryAnotherWayLink()>
            <form id="kc-select-try-another-way-form" action="${url.loginAction}" method="post">
                <input type="hidden" name="tryAnotherWay" value="on"/>
                <button type="submit" class="oa-linkknop" id="try-another-way">${msg("doTryAnotherWay")}</button>
            </form>
        </#if>

        <#if switchOrganizationEnabled?? && switchOrganizationEnabled>
            <form id="kc-switch-organization-form" action="${url.loginAction}" method="post">
                <input type="hidden" name="switchOrganization" value="true"/>
                <button type="submit" class="oa-linkknop" id="switch-organization">${msg("doSwitchOrganization")}</button>
            </form>
        </#if>

        <#nested "socialProviders">

        <#if displayInfo>
            <div id="kc-info" class="${properties.kcSignUpClass!}">
                <div id="kc-info-wrapper" class="${properties.kcInfoAreaWrapperClass!}">
                    <#nested "info">
                </div>
            </div>
        </#if>
    </div>

    <footer class="oa-voet">
        <#if realm.internationalizationEnabled && locale.supported?size gt 1>
            <nav id="kc-locale" aria-label="${msg("oaTaal")}" class="oa-talen">
                <#list locale.supported as l>
                    <#if l.languageTag == locale.currentLanguageTag>
                        <span aria-current="true">${l.label}</span>
                    <#else>
                        <a class="utrecht-link" href="${l.url}" hreflang="${l.languageTag}" lang="${l.languageTag}">${l.label}</a>
                    </#if>
                </#list>
            </nav>
        </#if>
        <p class="utrecht-paragraph utrecht-paragraph--small">${msg("oaPrototype")}</p>
        <@loginFooter.content/>
    </footer>
  </main>
</div>
</body>
</html>
</#macro>
