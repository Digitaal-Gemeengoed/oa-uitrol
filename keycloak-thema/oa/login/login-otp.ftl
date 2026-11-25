<#-- Inloggen met de code uit de authenticator-app. Eigen versie van base/login-otp.ftl:
     bij meer dan één gekoppelde app (bijvoorbeeld na "Wachtwoord of authenticator kwijt?")
     staat de nieuwste voorgeselecteerd, met een herkenbare naam en een aanwijzing.
     Na een foute code blijft de keuze van de gebruiker staan. -->
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('totp'); section>
    <#if section="header">
        ${msg("doLogIn")}
    <#elseif section="form">
        <form id="kc-otp-login-form" class="${properties.kcFormClass!}" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
            <#assign apps = otpLogin.userOtpCredentials>
            <#if apps?size gt 1>
                <#assign gekozen = messagesPerField.existsError('totp')?then(otpLogin.selectedCredentialId, apps?last.id)>
                <fieldset class="utrecht-form-fieldset oa-app-keuze">
                    <legend class="utrecht-form-label">${msg("oaOtpKeuze")}</legend>
                    <#list apps as app>
                        <#assign naam = (app.userLabel?has_content && app.userLabel != "unnamed")?then(app.userLabel, msg("oaOtpZonderNaam", app?counter))>
                        <div class="utrecht-form-field utrecht-form-field--radio">
                            <input id="kc-otp-credential-${app?index}" class="utrecht-radio-button utrecht-radio-button--html-input" type="radio" name="selectedCredentialId" value="${app.id}" <#if app.id == gekozen>checked="checked"</#if>>
                            <label for="kc-otp-credential-${app?index}" class="utrecht-form-label utrecht-form-label--radio">${naam}<#if !app?has_next> ${msg("oaOtpNieuwste")}</#if></label>
                        </div>
                    </#list>
                    <p class="utrecht-form-field-description">${msg("oaOtpKeuzeUitleg")}</p>
                </fieldset>
            </#if>

            <div class="${properties.kcFormGroupClass!}">
                <div class="${properties.kcLabelWrapperClass!}">
                    <label for="otp" class="${properties.kcLabelClass!}">${msg("loginOtpOneTime")}</label>
                </div>
                <div class="${properties.kcInputWrapperClass!}">
                    <input id="otp" name="otp" autocomplete="one-time-code" inputmode="numeric" type="text" class="${properties.kcInputClass!}"
                           autofocus aria-invalid="<#if messagesPerField.existsError('totp')>true</#if>"
                           <#if messagesPerField.existsError('totp')>aria-describedby="input-error-otp-code"</#if> dir="ltr" />
                    <#if messagesPerField.existsError('totp')>
                        <span id="input-error-otp-code" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                            ${kcSanitize(messagesPerField.get('totp'))?no_esc}
                        </span>
                    </#if>
                </div>
            </div>

            <div class="${properties.kcFormGroupClass!}">
                <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                    <input class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!}" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}" />
                </div>
            </div>
        </form>
    </#if>
</@layout.registrationLayout>
